# __COURSE_CODE__ — __COURSE_TITLE__

Course materials. Pull from this repository; **submit graded work on __LMS__**,
not to git, unless the instructor says otherwise.

## Students: getting started

See **[QUICKSTART.md](QUICKSTART.md)**.

```bash
__CLONE_SNIPPET__
cd __COURSE_NAME__
git checkout main && git fetch origin
```

Then open:

- [QUICKSTART.md](QUICKSTART.md) — environment
- [docs/](docs/) — handbook, module cards, and [docs/slos.md](docs/slos.md) as they are authored
- [assignments/](assignments/) — graded prompts → submit on __LMS__
- [docs/ai-what-to-expect.md](docs/ai-what-to-expect.md) — AI expectations

## Repository map

| Path | Contents |
|:--|:--|
| `QUICKSTART.md` | Clone, environment, smoke test |
| `CONTRIBUTING.md` | Small materials fixes |
| `docs/` | Handbook, modules, projects, admin notes |
| `docs/ai-what-to-expect.md` | Student AI expectations |
| `lectures/` | Notes and (optional) Quarto sources |
| `assignments/` | Labs and prompts → __LMS__ |
| `data/` | Public sample data only |

## Faculty

Author on `develop` unless this repo says otherwise. Publish student-facing
materials on `main` (or the branch your offering uses). Do not pass
`symkit --scaffold` on a tree created by symcourse.
