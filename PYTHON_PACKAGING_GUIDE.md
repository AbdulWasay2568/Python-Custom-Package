# Python Packaging Guide for Shared Library

This guide provides step-by-step instructions on how to package your `ezBot Discord/Shared` project into a distributable Python package.

---

## 1. Recommended Project Structure

For a clean and professional package, it's recommended to follow the "src" layout or a standard flat layout. Currently, your code is in a `lib/` directory. To make it a proper package, ensure you have `__init__.py` files in every directory that should be treated as a package.

Current structure:
```text
Shared/
├── lib/
│   ├── __init__.py
│   ├── discord/
│   │   └── __init__.py
│   └── ...
├── pyproject.toml
├── setup.py
└── README.md
```

## 2. Configure `pyproject.toml`

The `pyproject.toml` file is the modern standard for defining Python build systems and project metadata. Update your existing `pyproject.toml` with the following content:

```toml
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "shared-lib"
version = "0.1.0"
description = "Shared library for common functionality and utilities"
readme = "README.md"
requires-python = ">=3.8"
authors = [
    {name = "Your Name", email = "your.email@example.com"}
]
dependencies = [
    "fastapi>=0.115.12",
    "SQLAlchemy>=2.0.41",
    "httpx>=0.28.1"
]
classifiers = [
    "Programming Language :: Python :: 3",
    "License :: OSI Approved :: MIT License",
    "Operating System :: OS Independent",
]

[project.urls]
Homepage = "https://github.com/yourusername/shared"
Repository = "https://github.com/yourusername/shared"

[tool.setuptools]
# This tells setuptools where to find your packages
# Since your packages are inside 'lib', we specify that.
package-dir = {"" = "."}
packages = ["lib", "lib.discord"]
```

> [!NOTE]
> I've moved your requirements from `lib/requirements.txt` into the `dependencies` section of `pyproject.toml`. This is the modern way to handle dependencies for packages.

## 3. Configure `setup.py` (Optional / Minimal)

Since you are using `pyproject.toml`, your `setup.py` can be kept very simple or even removed if you don't need backward compatibility with very old tools.

```python
from setuptools import setup

if __name__ == "__main__":
    setup()
```

## 4. Building the Package

To build your package (create a source distribution and a wheel), you should use the `build` tool.

1. **Install the build tool:**
   ```bash
   pip install build
   ```

2. **Run the build command from the project root:**
   ```bash
   python -m build
   ```
   This will create a `dist/` directory containing two files:
   - `shared_lib-0.1.0.tar.gz` (Source distribution)
   - `shared_lib-0.1.0-py3-none-any.whl` (Built distribution/Wheel)

## 5. Installing the Package Locally

Before publishing, it's good practice to install the package locally to test if everything works.

### Editable Install (Best for Development)
This allows you to make changes to your code and see them reflected immediately without re-installing.
```bash
pip install -e .
```

### Regular Install
```bash
pip install .
```

## 6. Publishing to PyPI (Optional)

If you want to share your package with the world on [PyPI](https://pypi.org/):

1. **Install Twine:**
   ```bash
   pip install twine
   ```

2. **Upload to PyPI:**
   ```bash
   python -m twine upload dist/*
   ```
   You will be prompted for your PyPI username and password (or an API token).

---

### Summary of Changes Required:
1. **Update `pyproject.toml`** with the dependencies and package directory settings shown above.
2. **Update `setup.py`** to be a simple wrapper or remove it if not needed.
3. **Verify `lib/__init__.py`** exists and exposes what you need.
