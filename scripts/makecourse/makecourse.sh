#!/usr/bin/env bash
# Scaffold a UNCG MSIA course master from the IAN 630 *shape* (runtime,
# layout, release wiring). Does not copy course content.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: makecourse.sh <course-name> [outdir] [options]

  course-name   Repo / directory name, e.g. ian-630 or ian-6x0
  outdir        Destination (default: ./<course-name> under cwd)

Options:
  --title TEXT     Human title (default: derived from course-name)
  --code TEXT      Display code, e.g. "IAN 630" (default: derived)
  --with-pages     Include GitHub Pages hub (site/ + workflow)
  -h, --help       Show this help

Existing files are left alone. Safe to re-run on a repo that already
has a README. Requires python3; uv is used to write uv.lock when present.

Templates live next to this script in templates/.
EOF
}

log() { printf '>>> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${SCRIPT_DIR}/templates"
[[ -d "${TEMPLATE_DIR}" ]] || die "templates not found at ${TEMPLATE_DIR}"

COURSE_NAME=""
OUTDIR=""
COURSE_TITLE=""
COURSE_CODE=""
WITH_PAGES=0
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --title)
      [[ $# -ge 2 ]] || die "--title needs a value"
      COURSE_TITLE="$2"
      shift 2
      ;;
    --code)
      [[ $# -ge 2 ]] || die "--code needs a value"
      COURSE_CODE="$2"
      shift 2
      ;;
    --with-pages)
      WITH_PAGES=1
      shift
      ;;
    --)
      shift
      POSITIONAL+=("$@")
      break
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if [[ ${#POSITIONAL[@]} -lt 1 || ${#POSITIONAL[@]} -gt 2 ]]; then
  usage >&2
  exit 1
fi

COURSE_NAME="${POSITIONAL[0]}"
[[ "${COURSE_NAME}" =~ ^[A-Za-z0-9._-]+$ ]] || die "invalid course-name: ${COURSE_NAME}"

if [[ ${#POSITIONAL[@]} -eq 2 ]]; then
  OUTDIR="${POSITIONAL[1]}"
else
  OUTDIR="${PWD}/${COURSE_NAME}"
fi

if [[ -z "${COURSE_CODE}" ]]; then
  if [[ "${COURSE_NAME}" == ian-* ]]; then
    COURSE_CODE="IAN ${COURSE_NAME#ian-}"
  else
    COURSE_CODE="${COURSE_NAME}"
  fi
fi
if [[ -z "${COURSE_TITLE}" ]]; then
  COURSE_TITLE="${COURSE_CODE}"
fi

COURSE_PY="${COURSE_NAME//-/_}"
VENV_NAME="${COURSE_NAME}-venv"

CREATED=0
SKIPPED=0

render_template() {
  local src="$1"
  local dest="$2"
  COURSE_NAME="${COURSE_NAME}" \
  COURSE_TITLE="${COURSE_TITLE}" \
  COURSE_CODE="${COURSE_CODE}" \
  COURSE_PY="${COURSE_PY}" \
  VENV_NAME="${VENV_NAME}" \
  python3 - "$src" "$dest" <<'PY'
import os
import sys
from pathlib import Path

src = Path(sys.argv[1])
dest = Path(sys.argv[2])
text = src.read_text(encoding="utf-8")
for key in ("COURSE_NAME", "COURSE_TITLE", "COURSE_CODE", "COURSE_PY", "VENV_NAME"):
    text = text.replace(f"__{key}__", os.environ[key])
dest.parent.mkdir(parents=True, exist_ok=True)
dest.write_text(text, encoding="utf-8")
PY
}

install_file() {
  local rel="$1"
  local dest_rel="${2:-${rel%.tpl}}"
  local src="${TEMPLATE_DIR}/${rel}"
  local dest="${OUTDIR}/${dest_rel}"
  [[ -f "${src}" ]] || die "missing template: ${rel}"
  if [[ -e "${dest}" ]]; then
    log "skip (exists): ${dest_rel}"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi
  render_template "${src}" "${dest}"
  log "created: ${dest_rel}"
  CREATED=$((CREATED + 1))
}

install_copy() {
  local rel="$1"
  local mode="${2:-}"
  local src="${TEMPLATE_DIR}/${rel}"
  local dest="${OUTDIR}/${rel}"
  [[ -f "${src}" ]] || die "missing template: ${rel}"
  if [[ -e "${dest}" ]]; then
    log "skip (exists): ${dest#"${OUTDIR}"/}"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi
  mkdir -p "$(dirname "${dest}")"
  cp "${src}" "${dest}"
  if [[ "${mode}" == "exec" ]]; then
    chmod +x "${dest}"
  fi
  log "created: ${dest#"${OUTDIR}"/}"
  CREATED=$((CREATED + 1))
}

ensure_dir() {
  local d="${OUTDIR}/$1"
  mkdir -p "${d}"
}

log "Scaffolding ${COURSE_CODE} — ${COURSE_TITLE}"
log "Destination: ${OUTDIR}"
if [[ "${WITH_PAGES}" -eq 1 ]]; then
  log "Pages hub: yes"
else
  log "Pages hub: no (pass --with-pages to include)"
fi

ensure_dir assignments
ensure_dir data/public
ensure_dir docs/modules
ensure_dir docs/projects
ensure_dir docs/admin
ensure_dir lectures
ensure_dir scripts
ensure_dir .devcontainer
ensure_dir .github/workflows

install_file README.md.tpl
install_file QUICKSTART.md.tpl
install_file CONTRIBUTING.md.tpl
install_file AGENTS.md.tpl
install_file pyproject.toml.tpl
install_file gitignore.tpl .gitignore
install_file Containerfile.tpl
install_file .devcontainer/devcontainer.json.tpl
install_copy .github/workflows/release.yml
install_copy scripts/container-entrypoint.sh exec
install_copy scripts/install-learner-agents.sh exec
install_file docs/ai-what-to-expect.md.tpl
install_file docs/modules/README.md.tpl
install_file docs/projects/README.md.tpl
install_file docs/admin/README.md.tpl
install_file assignments/README.md.tpl
install_file data/README.md.tpl
install_file lectures/README.md.tpl
install_file lectures/_quarto.yml.tpl

if [[ ! -e "${OUTDIR}/data/public/.gitkeep" ]]; then
  touch "${OUTDIR}/data/public/.gitkeep"
  log "created: data/public/.gitkeep"
  CREATED=$((CREATED + 1))
else
  log "skip (exists): data/public/.gitkeep"
  SKIPPED=$((SKIPPED + 1))
fi

if [[ "${WITH_PAGES}" -eq 1 ]]; then
  ensure_dir site
  install_file site/README.md.tpl
  install_file site/index.html.tpl
  install_file scripts/build-pages.sh.tpl
  if [[ -f "${OUTDIR}/scripts/build-pages.sh" ]]; then
    chmod +x "${OUTDIR}/scripts/build-pages.sh"
  fi
  install_file .github/workflows/pages.yml.tpl
fi

if [[ -f "${OUTDIR}/pyproject.toml" ]] && command -v uv >/dev/null 2>&1; then
  if [[ -f "${OUTDIR}/uv.lock" ]]; then
    log "skip (exists): uv.lock"
    SKIPPED=$((SKIPPED + 1))
  else
    log "writing uv.lock"
    (cd "${OUTDIR}" && uv lock)
    CREATED=$((CREATED + 1))
  fi
elif [[ ! -f "${OUTDIR}/uv.lock" ]]; then
  warn "uv not on PATH; skip uv.lock. Run: cd ${OUTDIR} && uv lock"
fi

if [[ ! -d "${OUTDIR}/.git" ]]; then
  git -C "${OUTDIR}" init -b develop >/dev/null
  log "git init (default branch develop)"
fi

log "Done. created=${CREATED} skipped=${SKIPPED}"
log "Next: edit README, add a handbook when the spine is stable."
log "Do not commit .agents/ / .grok/ / .claude/ / .codex/."
