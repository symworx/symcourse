# ================================================== #
# OS-SPECIFIC
# ================================================== #

# --- macOS ---
.DS_Store
.AppleDouble
.LSOverride

# --- Windows ---
Thumbs.db
ehthumbs.db
Desktop.ini
$RECYCLE.BIN/

# --- Linux ---
.Trash-*

# ================================================== #
# EDITORS / IDEs
# ================================================== #

# --- Emacs ---
*~
\#*\#
.\#*
*.elc
eln-cache/
.emacs.d/.local/
.emacs.d/.cache/
.emacs.d/.session/
.tramp
.projectile
.projectile-bookmarks.eld

# --- Vim ---
*.swp
*.swo
*.swm
*.sw?
*.viminfo

# --- VS Code ---
.vscode/
.vscode-test/

# --- JetBrains (PyCharm) ---
.idea/

# ================================================== #
# PYTHON / UV / ENVIRONMENTS
# ================================================== #
.env

# --- Bytecode ---
__pycache__/
*.py[cod]
*$py.class

# --- uv ---
.venv/
# Commit uv.lock for reproducible student/container installs
# uv.lock

# --- Virtualenvs ---
env/
venv/
ENV/
env.bak/
venv.bak/

# --- PEP 582 ---
__pypackages__/

# ================================================== #
# BUILD / PACKAGING
# ================================================== #

build/
dist/
downloads/
eggs/
.eggs/
sdist/
wheels/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# ================================================== #
# TESTING / COVERAGE
# ================================================== #

.tox/
.nox/
.coverage
.coverage.*
.cache/
pytest_cache/
.pytest_cache/
hypothesis/
.hypothesis/
nosetests.xml
coverage.xml
*.cover
*.py,cover
cover/

# ================================================== #
# DOCUMENTATION / STATIC SITE
# ================================================== #

docs/_build/

# GitHub Pages *build* output (source HTML hub lives in tracked `site/` when used)
_site/

# Quarto lecture render (merged into _site/lectures/ at Pages build)
lectures/_built/
lectures/.quarto/
**/.quarto/

# ================================================== #
# JUPYTER / IPYTHON
# ================================================== #

.ipynb_checkpoints/
profile_default/
ipython_config.py

# ================================================== #
# PROJECT / TOOLING
# ================================================== #

# --- mkdocs (if used later): build elsewhere; do not ignore course hub `site/` ---
# site/   # intentionally tracked when the course has an HTML study hub

#  --- PyInstaller ---
*.spec
*.manifest

# --- Cython ---
cython_debug/

# Rope ---
.ropeproject/

# --- Spyder ---
.spyderproject
.spyproject

# --- Pyre / Pytype / Mypy ---
.pyre/
.pytype/
.mypy_cache/
.dmypy.json
dmypy.json

# ================================================== #
# CONTAINERS / DEVCONTAINERS
# ================================================== #

# --- VS Code devcontainer metadata ---
.devcontainer/.env
.devcontainer/.cache/

# --- Podman / Docker ---
*.pid
container-build/
container-cache/

# ================================================== #
# COURSE DATA (never commit restricted extracts)
# ================================================== #

data/private/
*.duckdb
*.parquet
# Add course-specific DUA patterns here (e.g. data/mimic*/ ) when needed.

# ================================================== #
# MISC
# ================================================== #

tags
tmp/
*.log

# ================================================== #
# AI
# ================================================== #
# Local agent trees only (container installs learner packs at start; do not commit)
.agents/*
.grok/*
.claude/*
.codex/*
.symkit/
CLAUDE.md

/.quarto/
**/*.quarto_ipynb
