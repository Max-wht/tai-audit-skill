# Tai Audit Skill

Tai Audit Skill is a business-flow-first smart contract audit skill for Claude Code, with Codex-compatible installation support.

The repository maintains one skill:

```text
skills/tai-audit/   Claude Code / Codex skill bundle
```

`x-ray` is an external companion skill from [pashov/skills](https://github.com/pashov/skills/tree/main/x-ray). Tai consumes `x-ray/` outputs in the audited project, but this repository does not vendor or maintain the x-ray source.

## What Tai Does

- Builds audit scope from business flows and entry points, not repo-wide grep alone.
- Runs a multi-agent loop over 7 root-cause families.
- Separates `Confirmed Vulnerability`, `Security Risk`, `Hardening / QA`, `Research Lead`, and `False Positive`.
- Persists reusable artifacts in the audited repo under `tai/artifacts/`.
- Writes final reports under `tai/business/`.

Supported triggers are unchanged:

```text
tai audit
deep audit
security review
```

## Install

Install Tai for Claude Code:

```bash
./scripts/install.sh
```

This installs or updates only Tai:

```text
~/.claude/skills/tai-audit
```

It does not install, update, or overwrite an existing `x-ray` skill.

If you already have x-ray installed, this is the recommended command:

```bash
./scripts/check.sh
./scripts/install.sh
```

Install or update Tai plus upstream x-ray for Claude Code:

```bash
./scripts/install.sh --with-xray
```

Use `--with-xray` only when x-ray is missing or when you intentionally want to refresh the upstream x-ray skill from `pashov/skills`.

Install for Codex:

```bash
./scripts/install.sh --target codex --with-xray
```

Install for both Claude Code and Codex:

```bash
./scripts/install.sh --target all --with-xray
```

Default destinations:

```text
Claude Code: ~/.claude/skills/tai-audit
Codex:       ~/.codex/skills/tai-audit
```

Override destinations with `CLAUDE_SKILLS_DIR` and `CODEX_SKILLS_DIR`.

For an existing x-ray install, omit `--with-xray` for Codex too:

```bash
./scripts/install.sh --target codex
```

Pin the upstream x-ray dependency with `X_RAY_REF`:

```bash
X_RAY_REF=v22042026 ./scripts/install.sh --with-xray
```

## Validate

Run the repository checks:

```bash
./scripts/check.sh
```

This verifies the skill bundle shape, required references, scripts, license files, and that no local vendored x-ray source references remain.

## x-ray Dependency Model

Tai expects one of these x-ray artifact sources, in order:

1. Existing audited-project output at `x-ray/x-ray.md` and `x-ray/entry-points.md`.
2. An installed external `x-ray` skill from [pashov/skills](https://github.com/pashov/skills/tree/main/x-ray).
3. A low-confidence fallback entry point map generated from Solidity `public`/`external` functions.

The fallback is only for degraded operation. For serious audits, install and run upstream x-ray first or install it with `./scripts/install.sh --with-xray`.

`./scripts/install.sh` deliberately does not manage x-ray unless `--with-xray` is provided. This keeps a working x-ray installation stable while you iterate on Tai.

## Project Layout

```text
skills/tai-audit/
  SKILL.md
  VERSION
  agents/openai.yaml
  references/
docs/
scripts/
```

`docs/` contains design notes for maintainers. Runtime skill behavior lives under `skills/tai-audit/`.

## License

MIT.
