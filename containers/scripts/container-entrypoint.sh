#!/bin/sh
# Lab image entrypoint: seed an empty /app from the generic course layout,
# install learner or instructor agents, then the user's command.
DEST="${SYMKIT_TARGET:-/app}"
SKELETON="/opt/course-skeleton"

if [ ! -f "${DEST}/docs/ai-what-to-expect.md" ] && [ -d "${SKELETON}" ]; then
  mkdir -p "${DEST}"
  cp -a "${SKELETON}/." "${DEST}/"
fi

if [ -x /usr/local/bin/install-agents ]; then
  /usr/local/bin/install-agents "${DEST}" || printf '%s\n' "agents: setup skipped"
fi
exec "$@"
