# __COURSE_CODE__ — __COURSE_TITLE__

UNCG ILRS / MSIA graduate course materials.

Pull course materials from this repository; **upload all graded work on Canvas**.

## Students: getting started

Follow the org-wide account / invitation steps on the
[UNCG MSIA organization page](https://github.com/uncg-msia),
then **[QUICKSTART.md](QUICKSTART.md)** (clone `main`, container or `uv`, smoke test).

Short version:

```bash
git clone https://github.com/uncg-msia/__COURSE_NAME__.git
cd __COURSE_NAME__
git checkout main && git fetch origin
```

Then open:

- [QUICKSTART.md](QUICKSTART.md) — environment
- [docs/](docs/) — handbook, module cards, and [docs/slos.md](docs/slos.md) as they are authored
- [assignments/](assignments/) — graded prompts → submit on Canvas
- [docs/ai-what-to-expect.md](docs/ai-what-to-expect.md) — AI expectations

## Repository map

| Path | Contents |
|:--|:--|
| `QUICKSTART.md` | Clone `main`, environment, smoke test |
| `CONTRIBUTING.md` | Small materials fixes (PRs target `develop`) |
| `docs/` | Handbook, modules, projects, admin notes |
| `docs/ai-what-to-expect.md` | Student AI expectations |
| `lectures/` | Notes and (optional) Quarto sources |
| `assignments/` | Labs and portfolio prompts → Canvas |
| `data/` | Public sample data only |
| `Containerfile` | Reproducible runtime |
| `.devcontainer/` | VS Code / Cursor dev container |

## Faculty

This is the **faculty master**, not a term repo. Author on `develop`. When students should see a drop: merge `develop` → `main`, then tag `vYYYY.S.m`. How-tos: [msia-faculty](https://github.com/uncg-msia/msia-faculty).
