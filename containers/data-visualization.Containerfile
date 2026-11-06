# Data visualization lab image (Python + R).
# Generic course layout (shape=course, org=none — not the MSIA overlay).
# Build from the repository root:
#
#   podman build -f containers/data-visualization.Containerfile \
#     -t ghcr.io/symworx/symcourse-data-visualization:latest .
#   podman run --rm -it -v "$PWD:/app:z" -p 8888:8888 \
#     ghcr.io/symworx/symcourse-data-visualization:latest
#
# Agent packs (symkit, education harness):
#   --build-arg AGENT_ROLE=learner      # default
#   --build-arg AGENT_ROLE=instructor
#   podman run -e AGENT_ROLE=instructor ...   # override at start
ARG RUST_IMAGE=rust:1.85-bookworm
ARG SYMKIT_VERSION=0.3.1

FROM ${RUST_IMAGE} AS rust-tools
ARG SYMKIT_VERSION
WORKDIR /src/symcourse
COPY Cargo.toml Cargo.lock README.md LICENSE NOTICE.md catalog.yaml ./
COPY src ./src
COPY templates ./templates
RUN cargo install --locked --path . --root /opt/tools \
 && cargo install --locked --version "${SYMKIT_VERSION}" --root /opt/tools symkit \
 && rm -rf /usr/local/cargo/registry /usr/local/cargo/git

FROM python:3.14-slim-bookworm
ARG SYMKIT_VERSION=0.3.1
ARG AGENT_ROLE=learner
ARG COURSE_NAME=data-visualization
ARG COURSE_NUMBER=DATA-VIZ
ARG COURSE_TITLE="Data Visualization"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    SYMKIT_VERSION=${SYMKIT_VERSION} \
    AGENT_ROLE=${AGENT_ROLE} \
    COURSE_NAME=${COURSE_NAME} \
    COURSE_NUMBER=${COURSE_NUMBER} \
    COURSE_TITLE=${COURSE_TITLE} \
    COURSE_LABEL=${COURSE_NAME} \
    UV_PROJECT_ENVIRONMENT=/opt/data-visualization-venv \
    PATH="/opt/data-visualization-venv/bin:${PATH}"

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY --from=rust-tools /opt/tools/bin/symkit /usr/local/bin/symkit
COPY --from=rust-tools /opt/tools/bin/symcourse /usr/local/bin/symcourse

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      git \
      fonts-dejavu-core \
      libcurl4-openssl-dev \
      libfontconfig1-dev \
      libfreetype6 \
      libfreetype6-dev \
      libfribidi-dev \
      libgomp1 \
      libharfbuzz-dev \
      libpng-dev \
      libpng16-16 \
      libssl-dev \
      libxml2-dev \
      g++ \
      gfortran \
      make \
      r-base \
      r-base-dev \
 && for pkg in \
      r-cran-dplyr \
      r-cran-ggplot2 \
      r-cran-knitr \
      r-cran-readr \
      r-cran-rmarkdown \
      r-cran-scales \
      r-cran-tibble \
      r-cran-tidyr \
      r-cran-viridis \
    ; do apt-get install -y --no-install-recommends "$pkg" || true; done \
 && rm -rf /var/lib/apt/lists/* \
 && git config --system --add safe.directory /app \
 && git config --system --add safe.directory /opt/course-skeleton

COPY containers/scripts/seed-course.sh /usr/local/bin/seed-course
COPY containers/scripts/install-agents.sh /usr/local/bin/install-agents
COPY containers/scripts/container-entrypoint.sh /usr/local/bin/container-entrypoint
RUN chmod +x /usr/local/bin/seed-course /usr/local/bin/install-agents /usr/local/bin/container-entrypoint

WORKDIR /opt/course-skeleton
RUN seed-course /opt/course-skeleton

COPY containers/data-visualization/pyproject.toml /opt/course-skeleton/pyproject.toml
COPY containers/data-visualization/install-r-packages.R /tmp/install-r-packages.R
RUN uv sync \
 && Rscript /tmp/install-r-packages.R \
 && rm -f /tmp/install-r-packages.R \
 && mkdir -p /app \
 && cp -a /opt/course-skeleton/. /app/

WORKDIR /app
EXPOSE 8888
ENTRYPOINT ["/usr/local/bin/container-entrypoint"]
CMD ["/bin/bash"]
