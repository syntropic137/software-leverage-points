#!/usr/bin/env bash
# Every SKILL.md frontmatter block must be valid YAML with a string `description`.
#
# WHY: four skills shipped with an unquoted description containing ": ", which
# YAML reads as a mapping, not a string:
#
#   description: Use when reviewing testing concerns: pyramid coverage
#                                                   ^ makes this a mapping
#
# yaml.safe_load raises "mapping values are not allowed here", so every
# frontmatter consumer rejects the skill. It was invisible because nothing
# parsed the frontmatter in CI -- the skills looked fine to a human reader.
set -euo pipefail

python3 - "$@" <<'PY'
import pathlib
import sys

try:
    import yaml
except ImportError:
    print("PyYAML is required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2) from None

failures: list[str] = []
checked = 0

for path in sorted(pathlib.Path("skills").glob("*/SKILL.md")):
    text = path.read_text()
    parts = text.split("---")
    if len(parts) < 3:
        failures.append(f"{path}: no frontmatter block")
        continue
    checked += 1
    try:
        data = yaml.safe_load(parts[1])
    except yaml.YAMLError as exc:
        first = str(exc).splitlines()[0]
        failures.append(
            f"{path}: invalid YAML frontmatter ({first}). "
            "A description containing ': ' must be quoted."
        )
        continue
    if not isinstance(data, dict):
        failures.append(f"{path}: frontmatter is not a mapping")
        continue
    for field in ("name", "description"):
        value = data.get(field)
        if not isinstance(value, str) or not value.strip():
            failures.append(f"{path}: '{field}' must be a non-empty string, got {type(value).__name__}")

print(f"checked {checked} SKILL.md frontmatter blocks")
if failures:
    print("\nFAILURES:")
    for f in failures:
        print(f"  {f}")
    raise SystemExit(1)
print("all frontmatter valid")
PY
