[project]
name = "__COURSE_NAME__"
version = "0.0.0"
description = "__COURSE_CODE__ — __COURSE_TITLE__"
requires-python = ">=3.13"
dependencies = [
    "matplotlib",
    "numpy",
    "pandas",
    "pydantic",
    "scikit-learn",
]

[dependency-groups]
# Optional tooling — installed by default with `uv sync` (no pre-commit hooks)
dev = [
    "mypy",
    "ruff",
]

[tool.uv]
# uv manages the environment and lockfile
default-groups = ["dev"]

[tool.ruff]
target-version = "py313"
line-length = 100
# Student and course Python only — not markdown courseware
src = ["assignments", "lectures"]
extend-exclude = [
    ".venv",
    "data",
    "docs",
]

[tool.ruff.lint]
# Keep rules gentle: style + imports only.
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings (incl. trailing whitespace)
    "I",   # isort
    "UP",  # pyupgrade (safe modernizations for 3.13+)
]
ignore = [
    "E501",  # line length — formatter handles wrap; exploratory code can be long
]

[tool.ruff.lint.isort]
known-first-party = ["__COURSE_PY__"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
line-ending = "lf"
docstring-code-format = true

[tool.mypy]
python_version = "3.13"
ignore_missing_imports = true
pretty = true
# mypy is optional for students; not enforced on submissions
