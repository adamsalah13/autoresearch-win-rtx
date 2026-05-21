FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HF_HUB_DISABLE_PROGRESS_BARS=1 \
    AUTORESEARCH_CACHE_DIR=/cache/autoresearch \
    UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_PYTHON=3.12 \
    PATH=/opt/venv/bin:/root/.local/bin:${PATH}

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

# Install uv from official installer.
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

WORKDIR /workspace

# Copy lockfiles first for better layer caching.
COPY pyproject.toml uv.lock ./

# Create project environment and install dependencies.
RUN uv sync --frozen --no-dev

# Copy the full repository.
COPY . .

# Ensure cache mount points exist.
RUN mkdir -p /cache/autoresearch /opt/venv

CMD ["bash"]
