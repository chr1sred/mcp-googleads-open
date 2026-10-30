#!/usr/bin/env python3
"""Valida as skills em skills/ / Validates the skills in skills/.

Checa: frontmatter (name, description), nome = pasta, limites de tamanho,
links internos, JSON das receitas e ausência de IDs reais de conta.

Uso / Usage: python3 tests/validate-skill.py
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
ACCOUNT_ID_RE = re.compile(r"\b\d{3}-?\d{3}-?\d{4}\b")
ALLOWED_FAKE_IDS = {"1234567890", "123-456-7890"}

errors: list[str] = []
checks = 0


def check(ok: bool, msg: str) -> None:
    global checks
    checks += 1
    print(f"  {'✔' if ok else '✘'} {msg}")
    if not ok:
        errors.append(msg)


def parse_frontmatter(text: str) -> dict[str, str]:
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return {}
    out = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            out[k.strip()] = v.strip()
    return out


skill_dirs = sorted(p for p in SKILLS.iterdir() if p.is_dir()) if SKILLS.exists() else []
check(bool(skill_dirs), "existe ao menos uma skill em skills/")

for d in skill_dirs:
    print(f"▶ {d.name}")
    skill_md = d / "SKILL.md"
    check(skill_md.exists(), "SKILL.md presente")
    if not skill_md.exists():
        continue
    text = skill_md.read_text(encoding="utf-8")
    fm = parse_frontmatter(text)
    name, desc = fm.get("name", ""), fm.get("description", "")

    check(bool(fm), "frontmatter YAML entre ---")
    check(name == d.name, f"name ({name!r}) igual ao nome da pasta")
    check(bool(NAME_RE.match(name)) and len(name) <= 64, "name em kebab-case, até 64 caracteres")
    check(0 < len(desc) <= 1024, f"description com 1–1024 caracteres ({len(desc)})")
    check("<" not in desc and ">" not in desc, "description sem < ou >")
    check(len(text.splitlines()) <= 500, f"SKILL.md com até 500 linhas ({len(text.splitlines())})")

    for link in re.findall(r"\]\(([^)#]+)\)", text):
        if not link.startswith("http"):
            check((d / link).exists(), f"link interno existe: {link}")

    for md in d.rglob("*.md"):
        body = md.read_text(encoding="utf-8")
        blocks = re.findall(r"```json\n(.*?)```", body, re.S)
        for i, block in enumerate(blocks, 1):
            try:
                json.loads(block)
                ok = True
            except json.JSONDecodeError as exc:
                ok = False
                print(f"     erro: {exc}")
            check(ok, f"{md.relative_to(d)}: bloco JSON {i} válido")
        leaked = [x for x in ACCOUNT_ID_RE.findall(body) if x not in ALLOWED_FAKE_IDS]
        check(not leaked, f"{md.relative_to(d)}: sem IDs reais de conta {leaked or ''}".rstrip())

print()
if errors:
    print(f"❌ {len(errors)} de {checks} verificações falharam")
    sys.exit(1)
print(f"✅ {checks} verificações passaram")
