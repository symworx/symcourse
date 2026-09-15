# ================================================== #
# OS-SPECIFIC
# ================================================== #

.DS_Store
.AppleDouble
.LSOverride
Thumbs.db
ehthumbs.db
Desktop.ini
$RECYCLE.BIN/
.Trash-*

# ================================================== #
# EDITORS / IDEs
# ================================================== #

*~
\#*\#
.\#*
.emacs.d/.local/
.emacs.d/.cache/
*.swp
*.swo
.viminfo
.vscode/
.idea/

# ================================================== #
# SECRETS / LOCAL ENV
# ================================================== #

.env

# ================================================== #
# COURSE DATA (never commit restricted extracts)
# ================================================== #

data/private/
*.duckdb
*.parquet

# ================================================== #
# DOCUMENTATION BUILD
# ================================================== #

docs/_build/
_site/
lectures/_built/
lectures/.quarto/
**/.quarto/
/.quarto/
**/*.quarto_ipynb

# ================================================== #
# MISC
# ================================================== #

tags
tmp/
*.log

# ================================================== #
# AI (local agent trees; do not commit)
# ================================================== #

.agents/
.grok/
.claude/
.codex/
.symkit/
CLAUDE.md

# ================================================== #
# MIGRATION DUMPS (PDF/Word import; keep README)
# ================================================== #

migration-docs/**
!migration-docs/README.md
