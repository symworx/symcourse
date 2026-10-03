# __COURSE_CODE__ — __COURSE_TITLE__

UNCG ILRS / MSIA graduate course materials.

Pull course materials from this repository; **upload all graded work on Canvas**.

## Students: getting started

Follow the org-wide account / invitation steps on the
[UNCG MSIA organization page](https://github.com/uncg-msia),
then **[QUICKSTART.md](QUICKSTART.md)** (clone `worx`, container or `uv`, smoke test).

Short version:

```bash
git clone https://github.com/uncg-msia/__COURSE_NAME__.git
cd __COURSE_NAME__
git checkout worx && git fetch origin
```

Then open:

- [QUICKSTART.md](QUICKSTART.md) — environment
- [docs/](docs/) — handbook, module cards, and [docs/slos.md](docs/slos.md) as they are authored
- [assignments/](assignments/) — graded prompts → submit on Canvas
- [docs/ai-what-to-expect.md](docs/ai-what-to-expect.md) — how AI use works in this course

## Repository map

| Path | Contents |
|:--|:--|
| `QUICKSTART.md` | Clone `worx`, environment, smoke test |
| `CONTRIBUTING.md` | Small materials fixes (PRs target `worx`) |
| `docs/` | Handbook, modules, and admin notes |
| `docs/slos.md` | Course outcomes, when that file has been written |
| `docs/ai-what-to-expect.md` | Student expectations for AI use |
| `lectures/` | Notes and optional slides, one directory per module |
| `assignments/` | Checkpoints, labs, and project prompts → Canvas |
| `data/` | Public sample data only |
| `Containerfile` | Reproducible runtime |
| `.devcontainer/` | VS Code / Cursor dev container |

Term dates, grading weights, and point values stay on **Canvas**.

## docs/

Handbook pages for the course.

| Path | What you will find |
|:--|:--|
| [`docs/modules/`](docs/modules/) | One session card per module: `module-NN.md` |
| [`docs/admin/`](docs/admin/) | Faculty logistics |
| [`docs/slos.md`](docs/slos.md) | Outcomes list, once it has been written |
| [`docs/ai-what-to-expect.md`](docs/ai-what-to-expect.md) | How AI use works in this course |

`NN` is a zero-padded number (`00`, `01`, `02`). Each folder README says which sections belong inside its files.

## lectures/

Teachable notes, one directory per module. The matching session card is `docs/modules/module-NN.md`.

```text
lectures/module-NN/notes.md
lectures/module-NN/index.qmd    # optional slides
```

The index of modules is [lectures/README.md](lectures/README.md).

## assignments/

Checkpoints, labs, and projects each have a directory:

```text
assignments/checkpoints/module-NN.md
assignments/labs/lab-NN.md
assignments/project/midterm.md
```

Submit the work on **Canvas**. See [assignments/README.md](assignments/README.md). Project briefs live in [assignments/project/](assignments/project/).

## data/

Public sample files only, under `data/public/`. See [data/README.md](data/README.md).

## Faculty

This is the **faculty master**, not a term repo. Author on `worx`. When students should see a drop, tag `vYYYY.S.m` on `worx`. How-tos: [msia-faculty](https://github.com/uncg-msia/msia-faculty).
