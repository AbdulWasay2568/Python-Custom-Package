# Using the Shared Library (`ezbot-shared`)

This guide explains how to integrate this library into your own Python projects.

---

## 1. Installation

Since this is a local shared library, you have two options for installing it.

### Option A: Install from a Local Folder (Recommended for Dev)
If you have the `Shared` code on your machine, navigate to your **own project's** terminal and run:

```bash
pip install -e "C:/Path/To/ezBot Discord/Shared"
```
*(Replace the path with the actual location of the Shared folder on your computer. Use quotes if there are spaces in the path.)*

### Option B: Install from a Git Repository
If the project is hosted on GitHub:
```bash
pip install git+https://github.com/yourusername/shared-repo.git
```

---

## 2. Basic Usage

Once installed, you can import the library just like `requests` or `os`.

### Using the Main Utilities
The core logic resides in the `stdsubs` module:

```python
from ezbot_shared import stdsubs

# Example: Execute a standard subsystem function
stdsubs.test()
```

### Using the Discord Helpers
If you need specific Discord exceptions or helpers:

```python
from ezbot_shared.discord import stdExceptions

try:
    # Your logic here
    pass
except stdExceptions.CommandError as e:
    print(f"Error occurred: {e.message}")
```

### Accessing Static Resources (Images, PDFs, etc.)
The library includes a `files/` directory with static assets. You can easily retrieve their absolute paths using the helper in `stdsubs`:

```python
from ezbot_shared import stdsubs

# Get the path to the entire 'files' folder
files_dir = stdsubs.get_resource_path()

# Get the absolute path to a specific file
image_path = stdsubs.get_resource_path("image.png")
print(f"File location: {image_path}")
```

---

## 3. Requirements

The library automatically handles the following dependencies when you install it:
- `fastapi`
- `SQLAlchemy`
- `httpx`

Ensure your Python version is **3.8 or higher**.

---

## 4. Development Workflow

If you make changes to the code inside the `Shared` folder and you installed it using the `-e` (editable) flag:
1. You **do not** need to re-install it.
2. Your other project will see the changes immediately.

If you add new dependencies to the library, remember to update the `dependencies` list in `pyproject.toml`.
