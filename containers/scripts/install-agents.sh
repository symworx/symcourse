#!/usr/bin/env bash
# Install education agent packs into a lab container checkout.
# AGENT_ROLE=learner (default) or instructor. Writes local .agents/ plus vendor
# adapters (gitignored). Does not commit. Learner overlay uses skip-worktree on
# AGENTS.md. Instructor install is in-place (same as `symcourse new`).
set -euo pipefail

ROOT="${1:-${SYMKIT_TARGET:-/app}}"
ROLE="$(printf '%s' "${AGENT_ROLE:-learner}" | tr '[:upper:]' '[:lower:]')"
STAMP_NAME=".symkit-agents-version"
COURSE_LABEL="${COURSE_LABEL:-$(basename "${ROOT}")}"
FORCE="${SYMKIT_AGENTS_FORCE:-${SYMKIT_LEARNER_FORCE:-}}"

log() { printf '%s %s agents: %s\n' "${COURSE_LABEL}" "${ROLE}" "$*"; }

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
  if [[ -n "${SYMKIT_VERSION:-}" ]]; then
    printf 'symkit %s\n' "${SYMKIT_VERSION}"
    return 0
  fi
  symkit guide 2>/dev/null | head -n 1 | tr -d '\r'
}

case "${ROLE}" in
  learner | instructor) ;;
  *)
    log "unknown AGENT_ROLE=${AGENT_ROLE:-} (use learner or instructor); skipping"
    exit 0
    ;;
esac

if [[ "${FORCE}" != "1" ]]; then
  if ! in_container; then
    log "not a container; skipping (set SYMKIT_AGENTS_FORCE=1 to override)"
    exit 0
  fi
  if [[ "${ROLE}" == "learner" ]] && has_faculty_tree "${ROOT}"; then
    log "faculty agent tree present; skipping"
    exit 0
  fi
  if [[ "${ROLE}" == "learner" ]] && ! student_branch; then
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
stamp_value="${version} role=${ROLE} adapters=all"
stamp="${ROOT}/.agents/${STAMP_NAME}"
if [[ "${FORCE}" != "1" && -n "${version}" && -f "${stamp}" ]]; then
  if [[ "$(cat "${stamp}")" == "${stamp_value}" ]]; then
    log "already installed (${stamp_value})"
    exit 0
  fi
fi

install_learner() {
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' EXIT

  mkdir -p "${tmp}/target"
  # Install into an empty tree so prune cannot touch the course checkout.
  if ! symkit install "${tmp}/target" \
    --harness teaching \
    --role learner \
    --docs slos \
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

  if [[ -f "${tmp}/target/docs/slos.md" && ! -f "${ROOT}/docs/slos.md" ]]; then
    mkdir -p "${ROOT}/docs"
    cp "${tmp}/target/docs/slos.md" "${ROOT}/docs/slos.md"
  fi

  # Student-only overlay: kit learner AGENTS.md instead of faculty materials file.
  # skip-worktree keeps git status clean so this is never a commit candidate.
  if [[ -f "${tmp}/target/AGENTS.md" ]]; then
    cp "${tmp}/target/AGENTS.md" "${ROOT}/AGENTS.md"
    if git_in_root rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git_in_root update-index --skip-worktree AGENTS.md >/dev/null 2>&1 || true
    fi
  fi
  if [[ -f "${tmp}/target/CLAUDE.md" ]]; then
    cp "${tmp}/target/CLAUDE.md" "${ROOT}/CLAUDE.md"
  fi
}

install_instructor() {
  if ! symkit install "${ROOT}" \
    --harness teaching \
    --role instructor \
    --docs slos \
    --adapters all \
    --yes >/dev/null; then
    log "symkit install failed"
    exit 0
  fi
}

if [[ "${ROLE}" == "instructor" ]]; then
  install_instructor
else
  install_learner
fi

if [[ -n "${version}" ]]; then
  mkdir -p "${ROOT}/.agents"
  printf '%s\n' "${stamp_value}" > "${stamp}"
fi

log "installed ${ROLE} pack under .agents/ (local only; do not commit)"
exit 0
