#!/usr/bin/env bash
# Copyright (c) 2026, PalEm Dynamics LLC
# Licensed under the Apache License, Version 2.0.
#
# Scaffold a course repo from catalog.yaml (shape + runtime + org overlay).
# Nested `symkit install` adds the teaching instructor pack and docs/slos.md
# when symkit is on PATH.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: makecourse.sh <course-name> [outdir] --course-number TEXT --course-title TEXT [options]

  course-name   Repo / directory name, e.g. bio-101 or ian-6xx
  outdir        Destination (default: ./<course-name> under cwd)

Prefer: ./cli/symcourse new <course-name> [outdir] …

Required:
  --course-number TEXT   Catalog / display code, e.g. "BIO 101" (alias: --code)
  --course-title TEXT    Human title (alias: --title)

Layout (catalog.yaml; defaults: shape=course runtime=none org=none):
  --shape ID         Folder spine (default: course)
  --runtime ID       none | uv (default: none)
  --org ID           none | msia (default: none)
  --preset ID        Named combo (msia = course + uv + msia). Flags override.
  --lms TEXT         Overrides org LMS (default: "the course LMS")
  --github-org TEXT  GitHub org for clone URLs (msia defaults to uncg-msia)

Options:
  --with-pages           Include GitHub Pages hub (site/ + workflow)
  --migration-docs       Create migration-docs/ for PDF/Word import (default)
  --no-migration-docs    Skip migration-docs/
  --symkit PATH          Nested installer (binary, or a checkout with cli/symkit)
  --no-agents            Skip nested `symkit install`
  --adapters SET   Passed to nested symkit (grok, claude, codex, all, none)
  -h, --help       Show this help

Existing files are left alone. Requires python3; uv writes uv.lock when the
uv runtime is selected and uv is on PATH. Nested symkit is the usual path
(--symkit, \$SYMKIT, PATH, or a sibling ../symkit clone). --no-agents skips it.

List ids: ./cli/symcourse list
EOF
}

log() { printf '>>> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CATALOG="${ROOT}/catalog.yaml"
TEMPLATE_DIR="${ROOT}/templates"
CATALOG_PY="${SCRIPT_DIR}/catalog.py"
[[ -f "${CATALOG}" ]] || die "catalog.yaml not found at ${CATALOG}"
[[ -d "${TEMPLATE_DIR}" ]] || die "templates not found at ${TEMPLATE_DIR}"

COURSE_NAME=""
OUTDIR=""
COURSE_TITLE=""
COURSE_CODE=""
SHAPE=""
RUNTIME=""
ORG=""
PRESET=""
LMS=""
GITHUB_ORG=""
WITH_PAGES=0
WITH_AGENTS=1
MIGRATION_DOCS=""
SYMKIT_ARG=""
ADAPTERS=""
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --title|--course-title)
      [[ $# -ge 2 ]] || die "$1 needs a value"
      COURSE_TITLE="$2"
      shift 2
      ;;
    --code|--course-number)
      [[ $# -ge 2 ]] || die "$1 needs a value"
      COURSE_CODE="$2"
      shift 2
      ;;
    --shape)
      [[ $# -ge 2 ]] || die "$1 needs a value"
      SHAPE="$2"
      shift 2
      ;;
    --runtime)
      [[ $# -ge 2 ]] || die "$1 needs a value"
      RUNTIME="$2"
      shift 2
      ;;
    --org)
      [[ $# -ge 2 ]] || die "$1 needs a value"
      ORG="$2"
      shift 2
      ;;
    --preset)
      [[ $# -ge 2 ]] || die "$1 needs a value"
      PRESET="$2"
      shift 2
      ;;
    --lms)
      [[ $# -ge 2 ]] || die "$1 needs a value"
      LMS="$2"
      shift 2
      ;;
    --github-org)
      [[ $# -ge 2 ]] || die "$1 needs a value"
      GITHUB_ORG="$2"
      shift 2
      ;;
    --with-pages)
      WITH_PAGES=1
      shift
      ;;
    --migration-docs)
      MIGRATION_DOCS=1
      shift
      ;;
    --no-migration-docs)
      MIGRATION_DOCS=0
      shift
      ;;
    --symkit)
      [[ $# -ge 2 ]] || die "$1 needs a value"
      SYMKIT_ARG="$2"
      shift 2
      ;;
    --no-agents)
      WITH_AGENTS=0
      shift
      ;;
    --adapters)
      [[ $# -ge 2 ]] || die "$1 needs a value"
      ADAPTERS="$2"
      shift 2
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

[[ -n "${COURSE_CODE}" ]] || die "--course-number (or --code) is required"
[[ -n "${COURSE_TITLE}" ]] || die "--course-title (or --title) is required"

if [[ -z "${MIGRATION_DOCS}" ]]; then
  if [[ -t 0 ]]; then
    printf 'Create migration-docs/ for PDF/DOCX import (dumps gitignored)? [Y/n] '
    read -r _mig || true
    case "${_mig}" in
      n|N|no|NO) MIGRATION_DOCS=0 ;;
      *) MIGRATION_DOCS=1 ;;
    esac
  else
    MIGRATION_DOCS=1
  fi
fi

COURSE_PY="${COURSE_NAME//-/_}"
VENV_NAME="${COURSE_NAME}-venv"

RESOLVE_ARGS=(
  python3 "${CATALOG_PY}"
  --catalog "${CATALOG}"
  resolve
  --plain
  --course-name "${COURSE_NAME}"
)
[[ -n "${SHAPE}" ]] && RESOLVE_ARGS+=(--shape "${SHAPE}")
[[ -n "${RUNTIME}" ]] && RESOLVE_ARGS+=(--runtime "${RUNTIME}")
[[ -n "${ORG}" ]] && RESOLVE_ARGS+=(--org "${ORG}")
[[ -n "${PRESET}" ]] && RESOLVE_ARGS+=(--preset "${PRESET}")
[[ -n "${LMS}" ]] && RESOLVE_ARGS+=(--lms "${LMS}")
[[ -n "${GITHUB_ORG}" ]] && RESOLVE_ARGS+=(--github-org "${GITHUB_ORG}")
[[ "${WITH_PAGES}" -eq 1 ]] && RESOLVE_ARGS+=(--pages)
[[ "${MIGRATION_DOCS}" -eq 1 ]] && RESOLVE_ARGS+=(--migration-docs)

RESOLVE_OUT="$("${RESOLVE_ARGS[@]}")"

declare -A TPL_VARS=()
TPL_VARS[COURSE_NAME]="${COURSE_NAME}"
TPL_VARS[COURSE_TITLE]="${COURSE_TITLE}"
TPL_VARS[COURSE_CODE]="${COURSE_CODE}"
TPL_VARS[COURSE_PY]="${COURSE_PY}"
TPL_VARS[VENV_NAME]="${VENV_NAME}"

SHAPE_ID=""
RUNTIME_ID=""
ORG_ID=""

while IFS=$'\t' read -r kind a b c; do
  [[ -z "${kind}" ]] && continue
  case "${kind}" in
    META)
      case "${a}" in
        shape) SHAPE_ID="${b}" ;;
        runtime) RUNTIME_ID="${b}" ;;
        org) ORG_ID="${b}" ;;
      esac
      ;;
    VAR)
      TPL_VARS["${a}"]="${b}"
      ;;
  esac
done <<< "${RESOLVE_OUT}"

CREATED=0
SKIPPED=0

render_template() {
  local src="$1"
  local dest="$2"
  python3 - "$src" "$dest" <<'PY'
import os
import sys
from pathlib import Path

src = Path(sys.argv[1])
dest = Path(sys.argv[2])
text = src.read_text(encoding="utf-8")
# Longer keys first so COURSE_NAME does not eat COURSE_NAME_FOO if we add one.
keys = sorted(
    (k[4:] for k in os.environ if k.startswith("TPL_")),
    key=len,
    reverse=True,
)
for key in keys:
    text = text.replace(f"__{key}__", os.environ["TPL_" + key])
dest.parent.mkdir(parents=True, exist_ok=True)
dest.write_text(text, encoding="utf-8")
PY
}

export_tpl_vars() {
  local k
  for k in "${!TPL_VARS[@]}"; do
    export "TPL_${k}=${TPL_VARS[$k]}"
  done
}

install_file() {
  local src_rel="$1"
  local dest_rel="$2"
  local src="${TEMPLATE_DIR}/${src_rel}"
  local dest="${OUTDIR}/${dest_rel}"
  [[ -f "${src}" ]] || die "missing template: ${src_rel}"
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
  local src_rel="$1"
  local dest_rel="$2"
  local mode="${3:-}"
  local src="${TEMPLATE_DIR}/${src_rel}"
  local dest="${OUTDIR}/${dest_rel}"
  [[ -f "${src}" ]] || die "missing template: ${src_rel}"
  if [[ -e "${dest}" ]]; then
    log "skip (exists): ${dest_rel}"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi
  mkdir -p "$(dirname "${dest}")"
  cp "${src}" "${dest}"
  if [[ "${mode}" == "exec" ]]; then
    chmod +x "${dest}"
  fi
  log "created: ${dest_rel}"
  CREATED=$((CREATED + 1))
}

append_fragment() {
  local src_rel="$1"
  local dest_rel="$2"
  local src="${TEMPLATE_DIR}/${src_rel}"
  local dest="${OUTDIR}/${dest_rel}"
  [[ -f "${src}" ]] || die "missing template: ${src_rel}"
  mkdir -p "$(dirname "${dest}")"
  if [[ -f "${dest}" ]] && grep -q "BEGIN symcourse runtime uv" "${dest}"; then
    log "skip (exists): ${dest_rel} runtime fragment"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi
  printf '\n' >> "${dest}"
  cat "${src}" >> "${dest}"
  log "appended: ${dest_rel} ← ${src_rel}"
  CREATED=$((CREATED + 1))
}

# Resolve a symkit executable: --symkit, $SYMKIT, PATH, then sibling clone.
resolve_symkit() {
  local cand="$1"
  if [[ -z "${cand}" ]]; then
    return 1
  fi
  if [[ -d "${cand}" ]]; then
    if [[ -x "${cand}/cli/symkit" ]]; then
      printf '%s\n' "${cand}/cli/symkit"
      return 0
    fi
    if [[ -x "${cand}/symkit" ]]; then
      printf '%s\n' "${cand}/symkit"
      return 0
    fi
    return 1
  fi
  if [[ -x "${cand}" ]]; then
    printf '%s\n' "${cand}"
    return 0
  fi
  if command -v "${cand}" >/dev/null 2>&1; then
    command -v "${cand}"
    return 0
  fi
  return 1
}

find_symkit() {
  local bin=""
  if [[ -n "${SYMKIT_ARG}" ]]; then
    if bin="$(resolve_symkit "${SYMKIT_ARG}")"; then
      printf '%s\n' "${bin}"
      return 0
    fi
    return 2
  fi
  if [[ -n "${SYMKIT:-}" ]]; then
    if bin="$(resolve_symkit "${SYMKIT}")"; then
      printf '%s\n' "${bin}"
      return 0
    fi
    return 3
  fi
  if command -v symkit >/dev/null 2>&1; then
    command -v symkit
    return 0
  fi
  if bin="$(resolve_symkit "${ROOT}/../symkit")"; then
    printf '%s\n' "${bin}"
    return 0
  fi
  return 1
}

install_agents() {
  local bin="" rc=0
  local cmd
  if [[ "${WITH_AGENTS}" -ne 1 ]]; then
    log "agents: skipped (--no-agents)"
    return 0
  fi
  bin="$(find_symkit)" && rc=0 || rc=$?
  if [[ "${rc}" -eq 2 ]]; then
    die "symkit not executable: ${SYMKIT_ARG} (pass a binary or a checkout with cli/symkit)"
  fi
  if [[ "${rc}" -eq 3 ]]; then
    die "SYMKIT is set but not executable: ${SYMKIT}"
  fi
  if [[ "${rc}" -ne 0 || -z "${bin}" ]]; then
    warn "symkit not found; skip agent install."
    warn "Install csymd/symkit, or pass --symkit PATH (binary or checkout)."
    warn "Next: symkit install ${OUTDIR} --harness teaching --role instructor --docs slos --yes"
    return 0
  fi
  cmd=("${bin}" install "${OUTDIR}" --harness teaching --role instructor --docs slos --yes)
  if [[ -n "${ADAPTERS}" ]]; then
    cmd+=(--adapters "${ADAPTERS}")
  fi
  log "Installing teaching harness via ${bin} (instructor + --docs slos; no --scaffold)"
  "${cmd[@]}"
}

export_tpl_vars

log "Scaffolding ${COURSE_CODE} — ${COURSE_TITLE}"
log "Destination: ${OUTDIR}"
log "Catalog: shape=${SHAPE_ID} runtime=${RUNTIME_ID} org=${ORG_ID}"
if [[ "${WITH_PAGES}" -eq 1 ]]; then
  log "Pages hub: yes"
else
  log "Pages hub: no (pass --with-pages to include)"
fi
if [[ "${WITH_AGENTS}" -eq 1 ]]; then
  log "Agents: nested symkit install (pass --no-agents to skip)"
else
  log "Agents: no"
fi
if [[ "${MIGRATION_DOCS}" -eq 1 ]]; then
  log "migration-docs/: yes (PDF/Word dumps gitignored)"
else
  log "migration-docs/: no"
fi

while IFS=$'\t' read -r kind a b c; do
  [[ -z "${kind}" ]] && continue
  case "${kind}" in
    DIR)
      mkdir -p "${OUTDIR}/${a}"
      ;;
    FILE)
      install_file "${a}" "${b}"
      ;;
    COPY)
      install_copy "${a}" "${b}" "${c:-}"
      ;;
    APPEND)
      append_fragment "${a}" "${b}"
      ;;
    KEEP)
      if [[ ! -e "${OUTDIR}/${a}" ]]; then
        mkdir -p "$(dirname "${OUTDIR}/${a}")"
        touch "${OUTDIR}/${a}"
        log "created: ${a}"
        CREATED=$((CREATED + 1))
      else
        log "skip (exists): ${a}"
        SKIPPED=$((SKIPPED + 1))
      fi
      ;;
  esac
done <<< "${RESOLVE_OUT}"

if [[ -f "${OUTDIR}/scripts/build-pages.sh" ]]; then
  chmod +x "${OUTDIR}/scripts/build-pages.sh"
fi

if [[ "${RUNTIME_ID}" == "uv" ]]; then
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
fi

if [[ ! -d "${OUTDIR}/.git" ]]; then
  git -C "${OUTDIR}" init -b develop >/dev/null
  log "git init (default branch develop)"
fi

install_agents

log "Done. created=${CREATED} skipped=${SKIPPED}"
log "Next: edit README, add a handbook when the spine is stable."
log "Do not commit .agents/ / .grok/ / .claude/ / .codex/."
log "Published SLOs: docs/slos.md (from nested symkit --docs slos)."
