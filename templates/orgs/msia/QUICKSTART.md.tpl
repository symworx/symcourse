# __COURSE_CODE__ — student quick start

Clone **`worx`**, run the course environment, then work from the handbook. **Upload graded work on Canvas**, not to GitHub.

Org-wide GitHub account / invitation steps: [github.com/uncg-msia](https://github.com/uncg-msia).

## 1. Clone `worx`

```bash
git clone https://github.com/uncg-msia/__COURSE_NAME__.git
cd __COURSE_NAME__
git checkout worx
git pull
```

If GitHub says **repository not found**, you have not been granted access yet, or you are signed in to a different GitHub account. Write the instructor with your GitHub username and the UNCG email on that account.

Stay on **`worx`** for labs and notes. Open a pull request against **`worx`** for a materials fix.

## 2. Environment (pick one)

Python **≥ 3.13** (`pyproject.toml`). The container image tracks **Python 3.14** and also includes **Rust** (`rustc` / `cargo`) plus `symkit` (from crates.io).

### Option A — VS Code or Cursor + Dev Container (recommended)

1. Install [Docker](https://docs.docker.com/get-docker/) or [Podman](https://podman.io/getting-started/installation), and [VS Code](https://code.visualstudio.com/) or [Cursor](https://cursor.com/).
2. Install the **Dev Containers** extension (VS Code: `ms-vscode-remote.remote-containers`). Cursor has the same command.
3. **File → Open Folder** and select the `__COURSE_NAME__` clone.
4. Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`) → **Dev Containers: Reopen in Container**.
5. Wait for the image build the first time. The window reloads when the container is ready; the File Explorer should show the **full clone** at `/app`.

This uses [`.devcontainer/devcontainer.json`](.devcontainer/devcontainer.json) and the repo `Containerfile`. The first image build is slower (Rust + `symkit`); later rebuilds use Docker/Podman layer cache.

On first start in the container (Dev Container or `docker`/`podman` run) **on `worx`**, a **local** learner agent pack is written under `.agents/` plus vendor mirrors (`.grok/`, `.claude/`, `.codex/`; gitignored). Stay on `worx` (see step 1). The container also overlays a learner `AGENTS.md` for coding agents; that overlay is not a git commit. Do not add `.agents/` or the vendor trees to a pull request. Local `uv` (Option C) does not run this step.

In VS Code Copilot Chat, use **Agent** mode and pick **learner** from the agent dropdown (from `.claude/agents/`).

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
| [README.md](README.md) | Course identity and outcomes |
| [docs/](docs/) | Handbook, module cards, SLO map (as authored) |
| [assignments/](assignments/) | Graded prompts → Canvas |
| [docs/ai-what-to-expect.md](docs/ai-what-to-expect.md) | AI expectations |

If this course publishes an HTML study hub, the README names the URL. That hub is study / self-check only.

## Troubleshooting

| Problem | Try |
|:--|:--|
| `repository not found` | Accept the GitHub invite; confirm the UNCG email on the account you are using |
| Dev Container command missing | Install the Dev Containers extension; reopen the folder |
| Container build fails | Docker/Podman running? Retry; first build is slower (Rust + `symkit`) |
| Explorer empty or only `pyproject.toml` / `.venv` | Rebuild the container (**Dev Containers: Rebuild Container**). The clone is bind-mounted at `/app`. On Fedora/RHEL, SELinux can hide the tree; the Dev Container sets `label=disable`, and CLI users should keep `:Z` on `-v`. |
| No `.agents/` after Reopen in Container | Confirm you are on `worx` (`git checkout worx && git pull`), then rebuild the container. |
| `.agents/` / `.claude/` / `.grok/` in `git status` | Leave them untracked; the learner pack is local to the container |
| `uv: command not found` | Install uv, or use Option A/B |
| Wrong Python | Use the container, or `uv python list` |
| Permission on volume mount | SELinux/Podman: check `:Z` or file ownership for your OS |

Optional polish for a `.py` file you will upload to Canvas (`ruff` is already in the environment):

```bash
uv run ruff format path/to/your-script.py
uv run ruff check --fix path/to/your-script.py
```

Notebooks are fine without ruff.

## Fixes to course materials

See [CONTRIBUTING.md](CONTRIBUTING.md). Graded work still goes to **Canvas**.
