# symcourse

Scaffold a **course repository**: layout, runtime, and identity. Agent
packs come from [csymd/symkit](https://github.com/csymd/symkit).

Private (cSYMd). Formerly `uncg-msia/etools`.

## Quick start

From a clone of this repository:

```bash
./cli/symcourse new ian-6xx \
  --course-number "IAN 6xx" \
  --course-title "Course title"

# existing directory (fills missing files only):
./cli/symcourse new ian-6xx /path/to/ian-6xx \
  --course-number "IAN 6xx" \
  --course-title "Course title"

# skip nested symkit install:
./cli/symcourse new ian-6xx \
  --course-number "IAN 6xx" \
  --course-title "Course title" \
  --no-agents

# optional HTML study hub:
./cli/symcourse new ian-6xx \
  --course-number "IAN 6xx" \
  --course-title "Course title" \
  --with-pages
```

`--course-number` and `--course-title` are required (`--code` and `--title`
are aliases). Existing files are skipped. Re-running on a repo that already
has a README is safe.

If `symkit` is on `PATH`, `new` then runs:

```bash
symkit install <outdir> --harness teaching --role instructor --docs slos --yes
```

No `--scaffold`. Layout is this tool’s job. If `symkit` is missing, the
course tree is still written and the install command is printed.

## What it writes

Always:

- `Containerfile`, `.devcontainer/`, `pyproject.toml`, `uv.lock`, `.gitignore`
- `QUICKSTART.md`, `CONTRIBUTING.md`, `AGENTS.md` (faculty materials file)
- `docs/` stubs (modules, projects, admin README/PLANNING, AI expectations)
- `assignments/`, `lectures/` (empty `_quarto.yml`), `data/public/`
- `scripts/container-entrypoint.sh`, `scripts/install-learner-agents.sh`
- `.github/workflows/release.yml` (org reusable release)

When nested `symkit` runs: `AGENTS-SYMKIT.md`, pointer on `AGENTS.md`,
`.agents/` (gitignored), grok adapter by default, `docs/slos.md`.

What it does **not** write: module cards, lecture notes, labs, filled SLO
map, handbook body, domain data. Do not pass `symkit --scaffold` on a
tree this tool created.

## Path ownership

| Path | Owner |
|:--|:--|
| Course identity, Containerfile, uv, `docs/admin/` logistics, org `AGENTS.md` | this repo |
| `docs/slos.md` | `symkit --docs slos` |
| `docs/ai-what-to-expect.md` | this repo (committed student handout) |
| `docs/ai/*` | symkit learner pack (copy-if-missing) |
| `.agents/`, adapters, `AGENTS-SYMKIT.md` | symkit |

Do not install `--role instructor` and then `--role learner` on the same
tree. Learner prune strips instructor agents.

## Tests

```bash
./tests/smoke.sh
```

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

Copyright (c) 2026, PalEm Dynamics LLC.
