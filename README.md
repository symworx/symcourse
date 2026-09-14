# etools

Faculty tooling for UNCG MSIA course repositories. **Private.** Students do not get this repo.

The useful command is `scripts/makecourse/makecourse.sh`. It scaffolds the **IAN 630 shape** (uv + Containerfile + learner-agent entrypoint + `develop`/`main` release wiring) without copying IAN 630 content.

## makecourse

From a clone of this repository:

```bash
./scripts/makecourse/makecourse.sh ian-6xx \
  --title "Course title" \
  --code "IAN 6xx"

# existing directory (fills missing files only):
./scripts/makecourse/makecourse.sh ian-6xx /path/to/ian-6xx \
  --title "Course title" \
  --code "IAN 6xx"

# optional HTML study hub (site/ + Pages workflow):
./scripts/makecourse/makecourse.sh ian-6xx --title "…" --with-pages
```

Existing files are skipped. Re-running on a repo that already has a README is safe.

What it writes (always):

- `Containerfile`, `.devcontainer/`, `pyproject.toml`, `uv.lock`, `.gitignore`
- `QUICKSTART.md`, `CONTRIBUTING.md`, `AGENTS.md` (faculty materials file)
- `docs/` stubs (modules, projects, admin, AI expectations)
- `assignments/`, `lectures/` (empty `_quarto.yml`), `data/public/`
- `scripts/container-entrypoint.sh`, `scripts/install-learner-agents.sh`
- `.github/workflows/release.yml` (org reusable release)

What it does **not** write: module cards, lecture notes, labs, SLO map, handbook body, domain data.

Shell wrapper (optional): `~/.bashrc.d/bin/makecourse.sh` should call this script, not the old copies under `~/.bashrc.d/bin/makecourse-tpl/`. Set `ETOOLS_HOME` if this clone is not at `~/worx/uncg-msia/etools`.

## Org conventions

| This repo | Course masters |
|:--|:--|
| Author on `develop` | Author on `develop`; students use `main` |
| Faculty team write; no students | Same, until a term offering |

Handbook: [msia-faculty/docs/new-course.md](https://github.com/uncg-msia/msia-faculty/blob/develop/docs/new-course.md).
