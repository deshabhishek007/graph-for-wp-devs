#!/usr/bin/env python3

import json
import pathlib
import sys

from jsonschema import Draft202012Validator, FormatChecker


def main() -> int:
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} SCHEMA MANIFEST", file=sys.stderr)
        return 2
    schema = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
    manifest = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
    validator = Draft202012Validator(schema, format_checker=FormatChecker())
    errors = sorted(validator.iter_errors(manifest), key=lambda error: list(error.path))
    if errors:
        for error in errors:
            location = ".".join(str(part) for part in error.path) or "<root>"
            print(f"{location}: {error.message}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
