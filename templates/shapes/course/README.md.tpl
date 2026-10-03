# __COURSE_CODE__ — __COURSE_TITLE__

Course materials. Pull from this repository; **submit graded work on __LMS__**,
not to git, unless the instructor says otherwise.

## Students: getting started

See **[QUICKSTART.md](QUICKSTART.md)**.

```bash
__CLONE_SNIPPET__
cd __COURSE_NAME__
git checkout worx && git fetch origin
```

Then open:

- [QUICKSTART.md](QUICKSTART.md) — environment
- [docs/](docs/) — handbook, module cards, and [docs/slos.md](docs/slos.md) as they are authored
- [assignments/](assignments/) — graded prompts → submit on __LMS__
- [docs/ai-what-to-expect.md](docs/ai-what-to-expect.md) — how AI use works in this course

## Repository map

| Path | Contents |
|:--|:--|
| `QUICKSTART.md` | Clone, environment, smoke test |
| `CONTRIBUTING.md` | Small materials fixes |
| `docs/` | Handbook, modules, and admin notes |
| `docs/slos.md` | Course outcomes, when that file has been written |
| `docs/ai-what-to-expect.md` | Student expectations for AI use |
| `lectures/` | Notes and optional slides, one directory per module |
| `assignments/` | Checkpoints, labs, and project prompts → __LMS__ |
| `data/` | Public sample data only |

Term dates, grading weights, and point values stay on **__LMS__**.

## docs/

Handbook pages for the course. Open the folder that matches the question.

| Path | What you will find |
|:--|:--|
| [`docs/modules/`](docs/modules/) | One session card per module: `module-NN.md` |
| [`docs/admin/`](docs/admin/) | Faculty logistics. Students can skip this |
| [`docs/slos.md`](docs/slos.md) | Outcomes list, once it has been written |
| [`docs/ai-what-to-expect.md`](docs/ai-what-to-expect.md) | How AI use works in this course |

`NN` is a zero-padded number (`00`, `01`, `02`). Each folder README says which sections belong inside its files.

## lectures/

Teachable notes, one directory per module. The matching session card is `docs/modules/module-NN.md`. Notes are what to study. The card is how the meeting runs.

```text
lectures/module-NN/notes.md
lectures/module-NN/index.qmd    # optional slides
```

The index of modules is [lectures/README.md](lectures/README.md).

## assignments/

What to do. Checkpoints, labs, and projects each have a directory:

```text
assignments/checkpoints/module-NN.md
assignments/labs/lab-NN.md
assignments/project/midterm.md
```

Submit the work on **__LMS__**. [assignments/README.md](assignments/README.md) describes this layout. Project briefs live in [assignments/project/](assignments/project/).

## data/

Public sample files only, under `data/public/`. Restricted extracts stay outside the repository. See [data/README.md](data/README.md).

## Faculty

Author on `worx`. Tag a release on `worx` when students should see a drop.
Do not pass `symkit --scaffold` on a tree created by symcourse.
