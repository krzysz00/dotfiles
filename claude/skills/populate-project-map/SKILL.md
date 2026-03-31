---
name: populate-project-map
description: Creates or updates a human-readable directory map for the currently active workspace. Use when onboarding to a new project or when the workspace layout has changed.
---

# Populate project map

Command to create a human-readable directory map for other the currently active VSCode/Cursor workspace.

## Steps

1. If a top-level `project-map.md` in the workspace directory, create one. Otherwise update the existing one.
2. Explore the project and find the main git repo and build directory. Usually these will be subdirectories inside the workspace.
3. Identify directories with binary files inside the build directory.
4. Identify the key binaries inside the build directory. Include executables and scripts only, no dynamic libraries or build artifacts.
4. Populate the file with the directory map. Double check that all paths actually exist.
5. Open the `project-map.md` file in the editor for user to inspect and ask for any modifications.


Do not include anything excepts paths to the key directories.

## Example:

```md
# Project Map

## Directories

- Worskpace dir: `/home/user/foo/bar`
- Source dir (git): `/home/user/foo/bar/src`
- Build dir (git): `/home/user/foo/bar/build`
- Binary dirs:
  * `/home/user/foo/bar/build/bin`
  * `/home/user/foo/bar/build/tools`
- Virtual environment: `/home/users/foo/bar/.venv`

## Binaries

- mlir-opt: `/home/user/foo/bar/build/bin/mlir-opt`
- clang: `...`
- llvm-lit: `...`
- ...

```
