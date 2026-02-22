FROM python:3.14

# Stop from writing .pyc files and ensure output is not buffered
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install uv (fast Python package manager)
RUN pip install --no-cache-dir uv

# Set working directory
WORKDIR /app

# Copy dependency files first for better caching
COPY pyproject.toml uv.lock ./

# Sync environment
RUN uv sync --frozen

# Default shell
CMD ["/bin/bash"]
