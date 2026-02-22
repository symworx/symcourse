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

# --- Bytecode ---
__pycache__/
*.py[cod]
*$py.class

# --- uv ---
.venv/
uv.lock

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
# DOCUMENTATION
# ================================================== #

docs/_build/
site/

# ================================================== #
# JUPYTER / IPYTHON
# ================================================== #

.ipynb_checkpoints/
profile_default/
ipython_config.py

# ================================================== #
# PROJECT / TOOLING
# ================================================== #

# --- mkdocs ---
/site

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
# MISC
# ================================================== #

tags
tmp/
*.log
