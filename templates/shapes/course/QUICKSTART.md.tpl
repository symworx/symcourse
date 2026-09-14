# __COURSE_CODE__ — student quick start

Clone the student-facing branch, then work from the handbook. **Submit graded
work on __LMS__**, not to git, unless the instructor says otherwise.

## 1. Clone

```bash
__CLONE_SNIPPET__
cd __COURSE_NAME__
git checkout main
git pull
```

Stay on **`main`** for labs and notes unless you are proposing a materials fix.

## 2. What to open next

| Start here | Why |
|:--|:--|
| [README.md](README.md) | Course identity |
| [docs/](docs/) | Handbook, module cards, SLO map (as authored) |
| [assignments/](assignments/) | Graded prompts → __LMS__ |
| [docs/ai-what-to-expect.md](docs/ai-what-to-expect.md) | AI expectations |

If this course ships a language runtime (container / `uv`), the instructor
will say so in this file or the handbook.

## Fixes to course materials

See [CONTRIBUTING.md](CONTRIBUTING.md). Graded work still goes to **__LMS__**.
