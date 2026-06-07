#!/usr/bin/env python3
"""Structural validation for the platform-sdlc-harness plugin.

Complements the marketplace-wide scripts/validate-plugins.sh (which checks
manifest JSON + frontmatter presence) with checks that script does NOT do:

  1. Every skills/*/SKILL.md has frontmatter with `name:` and `description:`.
  2. `name:` matches its directory (warning only — some skills may differ).
  3. No broken intra-plugin relative Markdown links (e.g. `](../foo/SKILL.md)`
     pointing at a skill/file that doesn't exist).
  4. Every command in hooks/hooks.json resolves to a file that exists.

Exit 0 = clean, 1 = errors found. Usage: validate-skills.py [PLUGIN_ROOT]
(default: the plugin root two levels up from this file).
"""
import json
import os
import re
import sys

PLUGIN_ROOT = os.path.abspath(
    sys.argv[1] if len(sys.argv) > 1
    else os.path.join(os.path.dirname(__file__), "..")
)

errors = []
warnings = []


def frontmatter(text):
    """Return the YAML frontmatter block (between the first two --- lines), or ''."""
    if not text.startswith("---"):
        return ""
    end = text.find("\n---", 3)
    return text[3:end] if end != -1 else ""


# ── 1 + 2: skill frontmatter ────────────────────────────────────────────────
skills_dir = os.path.join(PLUGIN_ROOT, "skills")
if os.path.isdir(skills_dir):
    for name in sorted(os.listdir(skills_dir)):
        skill_md = os.path.join(skills_dir, name, "SKILL.md")
        if not os.path.isfile(skill_md):
            continue
        with open(skill_md, encoding="utf-8") as fh:
            fm = frontmatter(fh.read())
        rel = os.path.relpath(skill_md, PLUGIN_ROOT)
        if not fm:
            errors.append(f"{rel}: missing YAML frontmatter")
            continue
        m = re.search(r"^name:\s*(.+)$", fm, re.MULTILINE)
        if not m:
            errors.append(f"{rel}: frontmatter missing `name:`")
        elif m.group(1).strip() != name:
            warnings.append(f"{rel}: name '{m.group(1).strip()}' != directory '{name}'")
        if not re.search(r"^description:\s*\S", fm, re.MULTILINE) and \
           not re.search(r"^description:\s*>", fm, re.MULTILINE):
            errors.append(f"{rel}: frontmatter missing `description:`")


# ── 3: broken skill-to-skill cross-references ───────────────────────────────
# Scoped to `.../SKILL.md` links — the See-also cross-reference pattern. Other
# Markdown links (e.g. illustrative `./src/foo/CONTEXT.md` paths inside
# *-FORMAT.md spec docs) are example content, not real plugin links.
LINK_RE = re.compile(r"\]\((?!https?://|#|mailto:)([^)\s]+?/SKILL\.md)(?:#[^)]*)?\)")
for dirpath, _dirs, files in os.walk(PLUGIN_ROOT):
    if "node_modules" in dirpath:
        continue
    for fn in files:
        if not fn.endswith(".md"):
            continue
        path = os.path.join(dirpath, fn)
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        for link in LINK_RE.findall(text):
            target = os.path.normpath(os.path.join(dirpath, link))
            if not os.path.exists(target):
                rel = os.path.relpath(path, PLUGIN_ROOT)
                errors.append(f"{rel}: broken link -> {link}")


# ── 4: hooks.json command paths exist ───────────────────────────────────────
hooks_json = os.path.join(PLUGIN_ROOT, "hooks", "hooks.json")
if os.path.isfile(hooks_json):
    with open(hooks_json, encoding="utf-8") as fh:
        try:
            data = json.load(fh)
        except json.JSONDecodeError as exc:
            errors.append(f"hooks/hooks.json: invalid JSON ({exc})")
            data = {}
    for event in data.get("hooks", {}).values():
        for matcher in event:
            for hook in matcher.get("hooks", []):
                cmd = hook.get("command", "")
                resolved = cmd.replace("${CLAUDE_PLUGIN_ROOT}", PLUGIN_ROOT)
                if resolved and not os.path.isfile(resolved):
                    errors.append(f"hooks/hooks.json: command not found -> {cmd}")


# ── report ──────────────────────────────────────────────────────────────────
for w in warnings:
    print(f"  ⚠ {w}")
if errors:
    print(f"VALIDATION FAILED — {len(errors)} error(s):")
    for e in errors:
        print(f"  ✗ {e}")
    sys.exit(1)
print(f"validate-skills: OK ({len(warnings)} warning(s))")
sys.exit(0)
