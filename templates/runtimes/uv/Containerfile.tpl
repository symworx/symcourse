# Rust + crates.io symkit in a builder so the final image has rustc/cargo/symkit
# without recompiling on Python-only layer changes.
ARG RUST_IMAGE=rust:1.85-bookworm
ARG SYMKIT_VERSION=0.2.0

FROM ${RUST_IMAGE} AS rust-tools
ARG SYMKIT_VERSION
RUN rustup set profile minimal \
 && cargo install --locked --version "${SYMKIT_VERSION}" symkit \
 && rm -rf /usr/local/cargo/registry /usr/local/cargo/git

FROM python:3.14-slim-bookworm
ARG SYMKIT_VERSION=0.2.0

# Stop writing .pyc files; keep stdout unbuffered
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV SYMKIT_VERSION=${SYMKIT_VERSION}
ENV COURSE_LABEL=__COURSE_NAME__
# Keep the course venv off /app so a bind-mount of the repo does not hide it.
ENV UV_PROJECT_ENVIRONMENT=/opt/__VENV_NAME__
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH="/opt/__VENV_NAME__/bin:/usr/local/cargo/bin:${PATH}"

# Install uv (fast Python package manager)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY --from=rust-tools /usr/local/cargo /usr/local/cargo
COPY --from=rust-tools /usr/local/rustup /usr/local/rustup

# cc so cargo remains usable; git for branch check + skip-worktree on AGENTS.md
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential ca-certificates git \
 && rm -rf /var/lib/apt/lists/* \
 && git config --system --add safe.directory /app

WORKDIR /app

# Dependency metadata first for better layer caching
COPY pyproject.toml ./
# Lockfile is optional in early scaffold; prefer frozen sync when present
COPY uv.lock* ./

RUN if [ -f uv.lock ]; then uv sync --frozen; else uv sync; fi

COPY scripts/install-learner-agents.sh /usr/local/bin/install-learner-agents
COPY scripts/container-entrypoint.sh /usr/local/bin/container-entrypoint
RUN chmod +x /usr/local/bin/install-learner-agents /usr/local/bin/container-entrypoint

ENTRYPOINT ["/usr/local/bin/container-entrypoint"]
CMD ["/bin/bash"]
