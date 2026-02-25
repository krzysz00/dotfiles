"""Tests for validate_marks.py."""

import os

import pytest

from validate_marks import validate, validate_format


class TestValidFormat:
    def test_named_mark(self):
        assert validate_format("entry: src/main.ts:1\n") == []

    def test_symbol_mark(self):
        assert validate_format("@myFunc: src/utils.ts:1\n") == []

    def test_anonymous_mark(self):
        assert validate_format("src/main.ts:1\n") == []

    def test_multiple_marks(self):
        assert validate_format("entry: src/main.ts:1\n@helper: src/utils.ts:1\nREADME.md:1\n") == []

    def test_comments_and_blanks(self):
        assert validate_format("# Section\n\nentry: src/main.ts:1\n\n# Another\nREADME.md:1\n") == []

    def test_html_comment_single_line(self):
        assert validate_format("<!-- hidden -->\nentry: src/main.ts:1\n") == []

    def test_html_comment_multi_line(self):
        assert validate_format("<!--\nhidden\n-->\nentry: src/main.ts:1\n") == []

    def test_cpp_namespace_in_name(self):
        assert validate_format("@mlir::populatePatterns: src/main.ts:1\n") == []

    def test_whitespace_around_marks(self):
        assert validate_format("  entry: src/main.ts:1  \n") == []

    def test_empty_file(self):
        assert validate_format("") == []

    def test_only_comments(self):
        assert validate_format("# Just comments\n# Nothing else\n") == []


class TestInvalidFormat:
    def test_invalid_line_number(self):
        errors = validate_format("entry: src/main.ts:abc\n")
        assert len(errors) == 1
        assert "invalid line number" in errors[0].message

    def test_no_colon(self):
        errors = validate_format("just some text\n")
        assert len(errors) == 1
        assert "no colon" in errors[0].message
        assert "expected" in errors[0].message

    def test_markdown_table(self):
        errors = validate_format("| col1 | col2 |\n")
        assert len(errors) == 1
        assert "markdown table" in errors[0].message
        assert "name: path:line" in errors[0].message

    def test_duplicate_location(self):
        errors = validate_format("a: src/main.ts:1\nb: src/main.ts:1\n")
        assert len(errors) == 1
        assert "duplicate location" in errors[0].message
        assert "line 1" in errors[0].message

    def test_duplicate_anonymous(self):
        errors = validate_format("src/main.ts:5\nsrc/main.ts:5\n")
        assert len(errors) == 1
        assert "duplicate location" in errors[0].message


class TestLineNumbers:
    def test_error_reports_correct_line(self):
        errors = validate_format("# header\n\nsrc/main.ts:1\nsrc/main.ts:1\n")
        assert len(errors) == 1
        assert errors[0].line_no == 4

    def test_multiple_errors(self):
        errors = validate_format("no-colon\n| table |\nsrc/main.ts:abc\n")
        assert len(errors) == 3
        assert errors[0].line_no == 1
        assert errors[1].line_no == 2
        assert errors[2].line_no == 3


class TestPathValidation:
    def test_existing_file(self, tmp_path):
        (tmp_path / "src").mkdir()
        (tmp_path / "src" / "main.ts").write_text("hello\n")
        assert validate("entry: src/main.ts:1\n", str(tmp_path)) == []

    def test_missing_file(self, tmp_path):
        errors = validate("entry: src/missing.ts:1\n", str(tmp_path))
        assert len(errors) == 1
        assert "file not found" in errors[0].message
        assert "remove this mark or fix the path" in errors[0].message

    def test_absolute_path(self, tmp_path):
        f = tmp_path / "main.ts"
        f.write_text("hello\n")
        assert validate(f"entry: {f}:1\n", str(tmp_path)) == []

    def test_format_and_path_errors_combined(self, tmp_path):
        errors = validate("| table |\nsrc/missing.ts:1\n", str(tmp_path))
        assert len(errors) == 2
        assert "markdown table" in errors[0].message
        assert "file not found" in errors[1].message
