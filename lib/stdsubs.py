from __future__ import annotations

import re
import json
from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple

import httpx
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from db.db_utils import get_guild_pk
from db.schema import GoogleDriveAuth
from pathlib import Path

def get_resource_path(filename: Optional[str] = None) -> Path:
    base_path = Path(__file__).parent / "files"
    if filename:
        return base_path / filename
    return base_path

def test():
    print("stdsubs module test function executed.")


async def refresh_access_token(refresh_token: str) -> dict:
    async with httpx.AsyncClient(timeout=20) as client:
        resp = await client.post(
            "https://oauth2.googleapis.com/token",
            data={
                "client_id": _require_env("GOOGLE_CLIENT_ID", GOOGLE_CLIENT_ID),
                "client_secret": _require_env("GOOGLE_CLIENT_SECRET", GOOGLE_CLIENT_SECRET),
                "refresh_token": refresh_token,
                "grant_type": "refresh_token",
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )

    data = resp.json() if resp.headers.get("content-type", "").startswith("application/json") else {}
    if resp.status_code != 200:
        raise HTTPException(401, "Google Drive auth failed. Please run /gdrive_connect again.")
    return data


async def _clear_drive_tokens(db: AsyncSession, auth_row: GoogleDriveAuth) -> None:
    auth_row.access_token = None
    auth_row.refresh_token = None
    auth_row.expires_at = None
    auth_row.scope = None
    if hasattr(auth_row, "scripts_folder_id"):
        auth_row.scripts_folder_id = None
    if hasattr(auth_row, "shortcuts_folder_id"):
        auth_row.shortcuts_folder_id = None
    await db.commit()


async def ensure_access_token(discord_user_id: str, guild_id: str, db: AsyncSession) -> str:
    user_pk = await _get_user_pk_strict(db, discord_user_id, guild_id)
    guild_pk = await get_guild_pk(db, guild_id=str(guild_id))
    if not guild_pk:
        raise HTTPException(404, "Guild not found.")

    auth_row = (
        (await db.execute(select(GoogleDriveAuth).filter_by(user_id=user_pk, guild_id=guild_pk)))
        .scalars()
        .first()
    )
    if not auth_row or not auth_row.refresh_token:
        raise HTTPException(401, "Google Drive not connected. Please run /gdrive_connect first.")

    now = datetime.now(timezone.utc)
    if auth_row.access_token and auth_row.expires_at and (auth_row.expires_at - now).total_seconds() > 60:
        return auth_row.access_token

    try:
        refreshed = await refresh_access_token(auth_row.refresh_token)
    except HTTPException:
        await _clear_drive_tokens(db, auth_row)
        raise

    auth_row.access_token = refreshed["access_token"]
    auth_row.expires_at = now + timedelta(seconds=int(refreshed.get("expires_in", 3600)))
    auth_row.scope = refreshed.get("scope") or auth_row.scope
    await db.commit()
    return auth_row.access_token


async def _find_scripts_folder(client: httpx.AsyncClient, headers: dict) -> Optional[dict]:
    resp = await client.get(
        "https://www.googleapis.com/drive/v3/files",
        params={
            "q": f"mimeType='{FOLDER_MIME}' and name='{_escape_drive_q_string(SCRIPTS_FOLDER_NAME)}' and trashed=false",
            "fields": "files(id,name,mimeType,modifiedTime)",
            "orderBy": "modifiedTime desc",
            "pageSize": 50,
        },
        headers=headers,
    )
    data = resp.json()
    if resp.status_code != 200:
        raise HTTPException(resp.status_code, data)
    files = data.get("files") or []
    return files[0] if files else None


async def _create_scripts_folder(client: httpx.AsyncClient, headers: dict) -> str:
    resp = await client.post(
        "https://www.googleapis.com/drive/v3/files",
        params={"fields": "id,name,mimeType"},
        headers={**headers, "Content-Type": "application/json"},
        json={"name": SCRIPTS_FOLDER_NAME, "mimeType": FOLDER_MIME},
    )
    data = resp.json()
    if resp.status_code not in (200, 201):
        raise HTTPException(resp.status_code, data)
    return data["id"]


async def _find_file_by_name_in_folder(
    client: httpx.AsyncClient, headers: dict, folder_id: str, filename: str
) -> Optional[dict]:
    r = await client.get(
        "https://www.googleapis.com/drive/v3/files",
        params={
            "q": f"'{folder_id}' in parents and trashed=false and name='{_escape_drive_q_string(filename)}'",
            "fields": "files(id,name,mimeType,modifiedTime)",
            "pageSize": 10,
        },
        headers=headers,
    )
    data = r.json()
    if r.status_code != 200:
        raise HTTPException(r.status_code, data)

    files = data.get("files") or []
    files.sort(key=lambda f: f.get("modifiedTime") or "", reverse=True)
    return files[0] if files else None


async def _create_example_script_file(
    client: httpx.AsyncClient, headers: dict, folder_id: str, ext: str
) -> str:
    ext = _normalize_extension(ext)
    filename = f"example{ext}"
    content = "# ADD YOUR COMMANDS HERE\n"

    files = {
        "metadata": (
            None,
            json.dumps({"name": filename, "parents": [folder_id], "mimeType": GOOGLE_DOC_MIME}),
            "application/json; charset=UTF-8",
        ),
        "file": ("content.txt", content.encode("utf-8"), "text/plain; charset=UTF-8"),
    }

    resp = await client.post(
        "https://www.googleapis.com/upload/drive/v3/files",
        params={"uploadType": "multipart", "fields": "id,name,mimeType,parents"},
        headers=headers,
        files=files,
    )
    data = resp.json()
    if resp.status_code not in (200, 201):
        raise HTTPException(resp.status_code, data)
    return data["id"]


async def _ensure_example_file(
    client: httpx.AsyncClient, headers: dict, folder_id: str, ext: str
) -> Tuple[str, bool]:
    ext = _normalize_extension(ext)
    filename = f"example{ext}"

    existing = await _find_file_by_name_in_folder(client, headers, folder_id, filename)
    if existing:
        return existing["id"], False

    new_id = await _create_example_script_file(client, headers, folder_id, ext)
    return new_id, True


async def ensure_scripts_folder_and_example(
    client: httpx.AsyncClient,
    headers: dict,
    db: AsyncSession,
    auth_row: GoogleDriveAuth,
    ext: str,
) -> Tuple[str, bool, str, bool]:
    ext = _normalize_extension(ext)

    lock_key = f"{getattr(auth_row, 'guild_id', 'guild')}:{getattr(auth_row, 'user_id', 'user')}:scripts"

    async with _lock_for(lock_key):

        folder_id = getattr(auth_row, "scripts_folder_id", None)
        if folder_id:
            check = await client.get(
                f"https://www.googleapis.com/drive/v3/files/{folder_id}",
                params={"fields": "id,mimeType,trashed"},
                headers=headers,
            )
            if check.status_code == 200:
                meta = check.json()
                if not meta.get("trashed") and meta.get("mimeType") == FOLDER_MIME:
                    example_id, example_created = await _ensure_example_file(client, headers, folder_id, ext)
                    return folder_id, False, example_id, example_created

            auth_row.scripts_folder_id = None
            await db.commit()

        folder = await _find_scripts_folder(client, headers)
        if folder:
            folder_id = folder["id"]
            auth_row.scripts_folder_id = folder_id
            await db.commit()

            example_id, example_created = await _ensure_example_file(client, headers, folder_id, ext)
            return folder_id, False, example_id, example_created

        folder_id = await _create_scripts_folder(client, headers)
        auth_row.scripts_folder_id = folder_id
        await db.commit()

        example_id, example_created = await _ensure_example_file(client, headers, folder_id, ext)
        return folder_id, True, example_id, example_created


async def _find_folder_by_name(client: httpx.AsyncClient, headers: dict, name: str) -> Optional[dict]:
    r = await client.get(
        "https://www.googleapis.com/drive/v3/files",
        params={
            "q": f"mimeType='{FOLDER_MIME}' and name='{_escape_drive_q_string(name)}' and trashed=false",
            "fields": "files(id,name)",
            "pageSize": 10,
        },
        headers=headers,
    )
    if r.status_code != 200:
        raise HTTPException(r.status_code, r.text)
    files = (r.json().get("files") or [])
    return files[0] if files else None


async def _create_folder(client: httpx.AsyncClient, headers: dict, name: str) -> dict:
    r = await client.post(
        "https://www.googleapis.com/drive/v3/files",
        params={"fields": "id,name"},
        headers={**headers, "Content-Type": "application/json"},
        json={"name": name, "mimeType": FOLDER_MIME},
    )
    if r.status_code not in (200, 201):
        raise HTTPException(r.status_code, r.text)
    return r.json()


async def ensure_admin_shortcuts_folder(
    client: httpx.AsyncClient,
    headers: dict,
    db: AsyncSession,
    auth_row: GoogleDriveAuth,
) -> Tuple[str, bool]:
    lock_key = f"{getattr(auth_row, 'guild_id', 'guild')}:{getattr(auth_row, 'user_id', 'user')}:shortcuts"

    async with _lock_for(lock_key):
        folder_id = getattr(auth_row, "shortcuts_folder_id", None)

        if folder_id:
            check = await client.get(
                f"https://www.googleapis.com/drive/v3/files/{folder_id}",
                params={"fields": "id,mimeType,trashed"},
                headers=headers,
            )
            if check.status_code == 200:
                meta = check.json()
                if not meta.get("trashed") and meta.get("mimeType") == FOLDER_MIME:
                    return folder_id, False

            auth_row.shortcuts_folder_id = None
            await db.commit()

        existing = await _find_folder_by_name(client, headers, SHORTCUTS_FOLDER_NAME)
        if existing:
            folder_id = existing["id"]
            auth_row.shortcuts_folder_id = folder_id
            await db.commit()
            return folder_id, False

        created = await _create_folder(client, headers, SHORTCUTS_FOLDER_NAME)
        folder_id = created["id"]
        auth_row.shortcuts_folder_id = folder_id
        await db.commit()
        return folder_id, True


def _safe_drive_folder_name(name: str, max_len: int = 120) -> str:
    if not name:
        return "unknown"
    name = name.strip()
    name = re.sub(r"\s+", " ", name)
    name = name.replace("/", "-").replace("\\", "-")
    return name[:max_len]


def _glob_path_to_regex(pattern: str) -> re.Pattern:
    """
    Converts glob-like Drive path to an extension-aware regex.
    """
    pattern = pattern.rstrip("/")

    # Detect extension-only pattern like */.s or /.s
    if pattern.endswith("/*") is False and "/." in pattern and pattern.split("/")[-1].startswith("."):
        ext = pattern.split("/")[-1]  # ".s", ".tar.gz"
        escaped_ext = re.escape(ext)
        return re.compile(rf"^.*/[^/]+{escaped_ext}$")

    escaped = re.escape(pattern)
    escaped = escaped.replace(r"\*", ".*")

    return re.compile(f"^{escaped}$")


async def _find_all_files_by_pattern(
    client,
    headers,
    extension: str,
    root_id: str = "root",
):
    regex = _glob_path_to_regex(extension)
    matches = []

    async def walk(folder_id: str, current_path: str):
        page_token = None

        while True:
            params = {
                "q": f"'{folder_id}' in parents and trashed = false",
                "fields": "nextPageToken, files(id, name, mimeType)",
                "pageSize": 1000,
            }

            if page_token:
                params["pageToken"] = page_token

            resp = await client.get(
                "https://www.googleapis.com/drive/v3/files",
                headers=headers,
                params=params,
            )
            resp.raise_for_status()

            data = resp.json()
            for f in data.get("files", []):
                file_id = f["id"]
                name = f["name"]
                mime = f.get("mimeType", "")

                # ✅ skip shortcuts entirely
                if mime == "application/vnd.google-apps.shortcut":
                    continue

                # ✅ fix: avoid leading "/" when current_path is empty
                path = f"{current_path}/{name}" if current_path else name

                if mime == "application/vnd.google-apps.folder":
                    await walk(file_id, path)
                else:
                    if regex.match(path):
                        f["path"] = path
                        matches.append(f)

            page_token = data.get("nextPageToken")
            if not page_token:
                break

    await walk(root_id, "")
    return matches