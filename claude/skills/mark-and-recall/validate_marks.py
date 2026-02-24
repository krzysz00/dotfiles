#!/usr/bin/env python3
"""Validate a marks.md file: checks format, path existence, and duplicates.

Usage: validate_marks.py [marks.md]
Exits 0 if valid, 1 if errors found.
"""

import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Error:
    line_no: int
    message: str


def parse_mark_path(before_line_num: str) -> str:
    """Extract the file path from the portion before the line number."""
    colon_space = before_line_num.find(": ")
    if colon_space != -1:
        potential_name = before_line_num[:colon_space].strip()
        potential_path = before_line_num[colon_space + 2 :].strip()
        if (
            potential_name
            and "/" not in potential_name
            and "\\" not in potential_name
            and potential_path
        ):
            return potential_path
    return before_line_num


def validate_format(content: str) -> list[Error]:
    """Validate marks format without checking the filesystem.

    Checks: syntax, line numbers, duplicates, no markdown tables.
    Returns a list of errors (empty = valid).
    """
    errors: list[Error] = []
    seen_locations: dict[str, int] = {}
    in_comment = False

    for line_no, raw_line in enumerate(content.splitlines(), start=1):
        line = raw_line.strip()

        # Multi-line HTML comments.
        if in_comment:
            if "-->" in line:
                in_comment = False
            continue
        if line.startswith("<!--"):
            if "-->" not in line:
                in_comment = True
            continue

        # Skip empty lines and # comments.
        if not line or line.startswith("#"):
            continue

        # Reject markdown tables.
        if line.startswith("|"):
            errors.append(Error(line_no, f"markdown table detected — use 'name: path:line' format instead: {line}"))
            continue

        # Must contain a colon.
        if ":" not in line:
            errors.append(Error(line_no, f"invalid format (no colon) — expected 'path:line' or 'name: path:line': {line}"))
            continue

        # Line number is after the last colon.
        last_colon = line.rfind(":")
        line_num_str = line[last_colon + 1 :].strip()
        if not re.fullmatch(r"\d+", line_num_str):
            errors.append(Error(line_no, f"invalid line number — mark must end with ':N' where N is a number: {line}"))
            continue

        before_line_num = line[:last_colon].strip()
        file_path = parse_mark_path(before_line_num)

        # Check duplicate locations.
        location = f"{file_path}:{line_num_str}"
        if location in seen_locations:
            first = seen_locations[location]
            errors.append(
                Error(
                    line_no,
                    f"duplicate location — remove this line or change the line number: {location} (first seen on line {first})",
                )
            )
        else:
            seen_locations[location] = line_no

    return errors


def validate(content: str, base_dir: str) -> list[Error]:
    """Validate marks content including filesystem path checks.

    Returns a list of errors (empty = valid).
    """
    errors = validate_format(content)
    in_comment = False

    for line_no, raw_line in enumerate(content.splitlines(), start=1):
        line = raw_line.strip()

        if in_comment:
            if "-->" in line:
                in_comment = False
            continue
        if line.startswith("<!--"):
            if "-->" not in line:
                in_comment = True
            continue

        if not line or line.startswith("#") or line.startswith("|") or ":" not in line:
            continue

        last_colon = line.rfind(":")
        line_num_str = line[last_colon + 1 :].strip()
        if not re.fullmatch(r"\d+", line_num_str):
            continue

        before_line_num = line[:last_colon].strip()
        file_path = parse_mark_path(before_line_num)

        if os.path.isabs(file_path):
            resolved = file_path
        else:
            resolved = os.path.join(base_dir, file_path)

        if not os.path.isfile(resolved):
            errors.append(Error(line_no, f"file not found — remove this mark or fix the path: {file_path}"))

    errors.sort(key=lambda e: e.line_no)
    return errors


def main() -> int:
    marks_file = sys.argv[1] if len(sys.argv) > 1 else "marks.md"
    path = Path(marks_file)

    if not path.is_file():
        print(f"error: file not found: {marks_file}", file=sys.stderr)
        return 1

    content = path.read_text()
    base_dir = str(path.resolve().parent)
    errors = validate(content, base_dir)

    for err in errors:
        print(f"{marks_file}:{err.line_no}: error: {err.message}", file=sys.stderr)

    if not errors:
        count = sum(
            1
            for line in content.splitlines()
            if line.strip()
            and not line.strip().startswith("#")
            and not line.strip().startswith("<!--")
            and not line.strip().startswith("|")
            and ":" in line.strip()
        )
        print(f"ok: {count} marks validated")
        return 0

    print(f"{len(errors)} error(s) found", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
