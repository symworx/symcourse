#!/usr/bin/env bash
# Install the teaching/learner agent tree into a student container checkout.
# Writes local .agents/ plus vendor adapters (gitignored) and overlays AGENTS.md
# with skip-worktree. Does not commit. Does not touch docs/. Skips faculty checkouts.
set -euo pipefail

ROOT="${1:-${SYMKIT_TARGET:-/app}}"
STAMP_NAME=".symkit-learner-version"
COURSE_LABEL="${COURSE_LABEL:-$(basename "${ROOT}")}"

log() { printf '%s learner agents: %s\n' "${COURSE_LABEL}" "$*"; }

# Bind mounts are often owned by the host user; container git runs as root.
git_in_root() {
  git -C "${ROOT}" -c "safe.directory=${ROOT}" "$@"
}

in_container() {
  [[ -f /.dockerenv ]] && return 0
  [[ -f /run/.containerenv ]] && return 0
  [[ -n "${REMOTE_CONTAINERS:-}" ]] && return 0
  [[ -n "${DEVCONTAINER:-}" ]] && return 0
  return 1
}

has_faculty_tree() {
  local base="$1"
  local marker
  for marker in \
    "${base}/.agents/agents/instructor.md" \
    "${base}/.agents/agents/materials-author.md" \
    "${base}/.grok/agents/instructor.md" \
    "${base}/.grok/agents/materials-author.md"; do
    if [[ -f "${marker}" ]]; then
      return 0
    fi
  done
  return 1
}

student_branch() {
  local branch
  if ! git_in_root rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 1
  fi
  branch="$(git_in_root rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  # worx is the default. main and master still install on checkouts that use those names.
  [[ "${branch}" == "worx" || "${branch}" == "main" || "${branch}" == "master" ]]
}

current_symkit_version() {
  # crates.io 0.1.1 has no --version flag; prefer the image pin, then guide header.
  if [[ -n "${SYMKIT_VERSION:-}" ]]; then
    printf 'symkit %s\n' "${SYMKIT_VERSION}"
    return 0
  fi
  symkit guide 2>/dev/null | head -n 1 | tr -d '\r'
}

if [[ "${SYMKIT_LEARNER_FORCE:-}" != "1" ]]; then
  if ! in_container; then
    log "not a container; skipping (set SYMKIT_LEARNER_FORCE=1 to override)"
    exit 0
  fi
  if has_faculty_tree "${ROOT}"; then
    log "faculty agent tree present; skipping"
    exit 0
  fi
  if ! student_branch; then
    log "not on worx; skipping (learner install runs on the default branch)"
    exit 0
  fi
fi

if ! command -v symkit >/dev/null 2>&1; then
  log "symkit not on PATH; skipping"
  exit 0
fi

if [[ ! -d "${ROOT}" ]]; then
  log "target ${ROOT} is not a directory; skipping"
  exit 0
fi

copy_local_tree() {
  local name="$1"
  if [[ -d "${tmp}/target/${name}" ]]; then
    mkdir -p "${ROOT}/${name}"
    cp -a "${tmp}/target/${name}/." "${ROOT}/${name}/"
  fi
}

drop_staff_personas() {
  local dir
  for dir in .agents .grok .claude; do
    rm -f \
      "${ROOT}/${dir}/agents/instructor.md" \
      "${ROOT}/${dir}/agents/materials-author.md" \
      "${ROOT}/${dir}/agents/ta.md"
  done
}

version="$(current_symkit_version || true)"
stamp_value="${version} adapters=all"
stamp="${ROOT}/.agents/${STAMP_NAME}"
if [[ "${SYMKIT_LEARNER_FORCE:-}" != "1" && -f "${ROOT}/.agents/agents/learner.md" && -n "${version}" && -f "${stamp}" ]]; then
  if [[ "$(cat "${stamp}")" == "${stamp_value}" ]]; then
    log "already installed (${stamp_value})"
    exit 0
  fi
fi

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

mkdir -p "${tmp}/target"
# Install into an empty tree so prune cannot touch the course checkout.
# --adapters all: .grok (Grok), .claude (VS Code Copilot / Claude), .codex.
if ! symkit install "${tmp}/target" \
  --harness teaching \
  --role learner \
  --adapters all \
  --yes >/dev/null; then
  log "symkit install failed"
  exit 0
fi

if [[ ! -d "${tmp}/target/.agents" ]]; then
  log "symkit did not write .agents/; skipping"
  exit 0
fi

copy_local_tree .agents
copy_local_tree .grok
copy_local_tree .claude
copy_local_tree .codex
copy_local_tree .symkit
drop_staff_personas

# Student-only overlay: kit learner AGENTS.md instead of faculty materials file.
# skip-worktree keeps git status clean so this is never a commit candidate.
if [[ -f "${tmp}/target/AGENTS.md" ]]; then
  cp "${tmp}/target/AGENTS.md" "${ROOT}/AGENTS.md"
  if git_in_root rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_in_root update-index --skip-worktree AGENTS.md >/dev/null 2>&1 || true
  fi
fi
# CLAUDE.md is a pointer at AGENTS.md; gitignored (local adapter only).
if [[ -f "${tmp}/target/CLAUDE.md" ]]; then
  cp "${tmp}/target/CLAUDE.md" "${ROOT}/CLAUDE.md"
fi

if [[ -n "${version}" ]]; then
  printf '%s\n' "${stamp_value}" > "${stamp}"
fi

log "installed learner pack under .agents/ (local only; do not commit)"
exit 0
