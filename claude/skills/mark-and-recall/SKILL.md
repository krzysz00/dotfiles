---
name: mark-and-recall
description: Read and write marks.md files to navigate codebases efficiently. Use when a marks.md file exists in the workspace, after significant codebase exploration, or when the user asks to document important code locations. Also use when the user says "mark it/them", "mark me", "mark this/these", "add a mark", "bookmark this/these", "save as marks", "save to marks", or otherwise asks to remember/mark code locations.
---

# Mark and Recall

Mark files (`marks.md`) are persistent bookmarks pointing to important code locations. They bridge context across agent sessions — marks you write today help future agents (and humans) navigate the codebase without re-exploring from scratch.

## Format

Three mark types — named, symbol (`@`), and anonymous:

```
# Section comments are standalone lines starting with #
name: path/to/file.ts:42
@functionName: src/utils.ts:15
src/config.ts:1
```

- Line numbers are 1-based; paths are relative to the workspace root (where `marks.md` lives)
- Only use absolute paths for locations outside the workspace tree
- `@` prefix indicates a symbol definition (function, class, method, variable)
- Mark names should be unique
- `#` comments must be on their own line.

## Reading

Check for `marks.md` in the workspace root before broader exploration. Marks represent curated human intent — the user placed them to direct your attention. Read the marked locations first.

If a mark looks stale (line number doesn't match the symbol name, or file is missing), fix or remove it.

## Writing

Update `marks.md` after exploring or modifying the codebase. This is a deliverable, not an afterthought.

1. Read existing `marks.md` first to avoid duplicates
2. Group related marks with `# Section` comments
3. Place most important marks first (positions 1-9 have quick keybindings)
4. Show the user what was added

**What to mark:** entry points, subsystem boundaries, non-obvious code paths, and anything the user asked about. Prefer named and symbol marks over anonymous ones.

## Creating

When no `marks.md` exists and you've done meaningful exploration, create one **in the workspace root directory** (not a subdirectory):

```
# Marks (see mark-and-recall skill)
# Examples: name: path:line | @symbol: path:line | path:line

```

Then populate it with your findings.

## Validation

After writing or updating marks, run `validate_marks.py` (in the same directory as this skill file):

```
python3 path/to/validate_marks.py [marks.md]
```

The validator checks for missing files, duplicate locations, invalid format, and markdown formatting. Errors are printed as `file:line: error: message` — fix every reported error before finishing.
