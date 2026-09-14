# __COURSE_CODE__ — student quick start

Clone the student-facing branch, run the course environment, then work from
the handbook. **Submit graded work on __LMS__**, not to git, unless the
instructor says otherwise.

## 1. Clone

```bash
__CLONE_SNIPPET__
cd __COURSE_NAME__
git checkout main
git pull
```

Stay on **`main`** for labs and notes unless you are proposing a materials fix.

## 2. Environment (pick one)

Python **≥ 3.13** (`pyproject.toml`). The container image tracks **Python 3.14**
and also includes **Rust** (`rustc` / `cargo`) plus `symkit` (from crates.io).

### Option A — VS Code or Cursor + Dev Container (recommended)

1. Install [Docker](https://docs.docker.com/get-docker/) or [Podman](https://podman.io/getting-started/installation), and [VS Code](https://code.visualstudio.com/) or [Cursor](https://cursor.com/).
2. Install the **Dev Containers** extension (VS Code: `ms-vscode-remote.remote-containers`). Cursor has the same command.
3. **File → Open Folder** and select the `__COURSE_NAME__` clone.
4. Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`) → **Dev Containers: Reopen in Container**.
5. Wait for the image build the first time.

This uses [`.devcontainer/devcontainer.json`](.devcontainer/devcontainer.json)
and the repo `Containerfile`.

On first start in the container **on `main`**, a **local** learner agent pack
is written under `.agents/` plus vendor mirrors (`.grok/`, `.claude/`,
`.codex/`; gitignored). Do not add those trees to a pull request. Local `uv`
(Option C) does not run this step.

### Option B — Docker or Podman CLI

```bash
docker build -t __COURSE_NAME__ -f Containerfile .
docker run -it --rm -v "$(pwd)":/app:Z -w /app __COURSE_NAME__
# or: podman build / podman run with the same flags
# :Z is for SELinux (Fedora / RHEL); drop it if your OS does not use SELinux
```

### Option C — Local `uv`

```bash
# https://docs.astral.sh/uv/
uv sync
source .venv/bin/activate   # Windows: .venv\Scripts\activate
```

## 3. Smoke test

From the repo root (container or venv):

```bash
uv run python -c "import pandas as pd, sklearn, numpy as np; print('ok', pd.__version__, np.__version__)"
```

Expected: one line starting with `ok` and version numbers.

## 4. What to open next

| Start here | Why |
|:--|:--|
| [README.md](README.md) | Course identity |
| [docs/](docs/) | Handbook, module cards, SLO map (as authored) |
| [assignments/](assignments/) | Graded prompts → __LMS__ |
| [docs/ai-what-to-expect.md](docs/ai-what-to-expect.md) | AI expectations |

## Troubleshooting

| Problem | Try |
|:--|:--|
| `repository not found` | Accept the GitHub invite; confirm you are signed in to the right account |
| Dev Container command missing | Install the Dev Containers extension; reopen the folder |
| Container build fails | Docker/Podman running? Retry; first build is slower (Rust + `symkit`) |
| No `.agents/` after Reopen in Container | Confirm you are on `main`, then rebuild the container |
| `.agents/` / `.claude/` / `.grok/` in `git status` | Leave them untracked; the learner pack is local |
| `uv: command not found` | Install uv, or use Option A/B |

Optional polish for a `.py` file (`ruff` is already in the environment):

```bash
uv run ruff format path/to/your-script.py
uv run ruff check --fix path/to/your-script.py
```

## Fixes to course materials

See [CONTRIBUTING.md](CONTRIBUTING.md). Graded work still goes to **__LMS__**.
