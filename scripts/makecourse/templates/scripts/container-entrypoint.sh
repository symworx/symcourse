#!/bin/sh
# Course container entrypoint: learner agent tree, then the user's command.
if [ -x /usr/local/bin/install-learner-agents ]; then
  /usr/local/bin/install-learner-agents /app || printf '%s\n' "learner agents: setup skipped"
fi
exec "$@"
