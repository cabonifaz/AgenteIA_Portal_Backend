# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.11-slim

# ---------- Builder stage ----------
FROM python:${PYTHON_VERSION} AS builder

WORKDIR /app

# gcc/g++ only live in this stage, in case a transitive dependency has no
# prebuilt wheel for the target arch. Not present in the final image.
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc g++ \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# ---------- Runtime stage ----------
FROM python:${PYTHON_VERSION} AS runtime

WORKDIR /app

# curl is only needed for the HEALTHCHECK below.
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 appuser \
    && useradd --uid 1000 --gid appuser --shell /bin/bash --create-home appuser

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY --chown=appuser:appuser . .

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8000/api/v1/health/check || exit 1

# Runs behind an ALB — trust its forwarded headers.
# Single worker: task sizing is 0.5 vCPU / 1GB, scaling is done via ECS
# desiredCount rather than in-process multi-worker uvicorn.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers", "--forwarded-allow-ips=*"]
