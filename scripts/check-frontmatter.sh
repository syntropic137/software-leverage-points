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
except ImportError:  # pragma: no cover - CI installs only `just`
    print(
        "PyYAML not available. Install it (pip install pyyaml) or run via a "
        "Python that has it; this check cannot silently pass without a parser.",
        file=sys.stderr,
    )
    raise SystemExit(2) from None

failures: list[str] = []
checked = 0

# Every tracked SKILL.md, not just skills/*/SKILL.md. A codex review caught that
# globbing one root skipped .claude/skills/, which contained a fifth file broken
# the same way -- the guard reported "checked 20" and passed.
paths = sorted(
    p for p in pathlib.Path(".").rglob("SKILL.md") if ".git/" not in str(p)
)

for path in paths:
    lines = path.read_text().splitlines()
    # `text.split("---")` matched "---" anywhere, so a file with prose before the
    # opening delimiter, or a closer like "---not-a-delimiter", parsed the wrong
    # slice and passed. Require the delimiters to be their own lines.
    if not lines or lines[0].strip() != "---":
        failures.append(f"{path}: frontmatter must open with '---' on line 1")
        continue
    try:
        end = next(i for i, ln in enumerate(lines[1:], start=1) if ln.strip() == "---")
    except StopIteration:
        failures.append(f"{path}: frontmatter has no closing '---' line")
        continue
    checked += 1
    try:
        data = yaml.safe_load("\n".join(lines[1:end]))
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
