# Contributing

Contributions should keep Tai focused on `tai-audit`. Do not vendor upstream `x-ray` source into this repository.

## Development

Run checks before submitting changes:

```bash
./scripts/check.sh
```

Use a temporary install directory when testing installer changes:

```bash
CLAUDE_SKILLS_DIR=$(mktemp -d) ./scripts/install.sh --target claude --with-xray
CODEX_SKILLS_DIR=$(mktemp -d) ./scripts/install.sh --target codex --with-xray
```

## Skill Design Rules

- Keep `skills/tai-audit/SKILL.md` concise enough to load as a coordinator prompt.
- Put detailed workflow material in one-level-deep files under `skills/tai-audit/references/`.
- Preserve the current classification split between confirmed vulnerabilities, security risks, hardening/QA, research leads, and false positives.
- Treat external `x-ray` as a dependency from `pashov/skills`, not as local source.

## Pull Requests

Include:

- What changed.
- Why the change matters for audit quality or installability.
- Which checks were run.
- Any regression corpus used, such as Sturdy or another public C4 benchmark.
