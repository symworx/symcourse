#!/usr/bin/env bash
# Write the generic (non-msia) course layout into DEST with `symcourse new`.
# Runtime is none: the image owns Python / R. Agents are installed at entrypoint.
set -euo pipefail

DEST="${1:-/opt/course-skeleton}"
COURSE_NAME="${COURSE_NAME:-course}"
COURSE_NUMBER="${COURSE_NUMBER:-COURSE}"
COURSE_TITLE="${COURSE_TITLE:-Course}"

log() { printf 'seed-course: %s\n' "$*"; }

if [[ ! -x "$(command -v symcourse || true)" ]]; then
  log "symcourse not on PATH"
  exit 1
fi

if [[ -f "${DEST}/docs/ai-what-to-expect.md" ]]; then
  log "layout already present at ${DEST}"
  exit 0
fi

log "symcourse new ${COURSE_NAME} → ${DEST} (shape=course org=none runtime=none)"
symcourse new "${COURSE_NAME}" "${DEST}" \
  --course-number "${COURSE_NUMBER}" \
  --course-title "${COURSE_TITLE}" \
  --no-agents
