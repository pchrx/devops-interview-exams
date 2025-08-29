# Builder stage
FROM python:3.9.19-slim@sha256:69e712dbe4c4a166527cbf69374533125cfb6ee93a5e39031a0191c741d386d7 AS builder
WORKDIR /opt/app
COPY requirements.txt ./
# Install dependencies into a relocatable prefix (no cache, no secrets)
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Final stage
FROM python:3.9.19-slim@sha256:69e712dbe4c4a166527cbf69374533125cfb6ee93a5e39031a0191c741d386d7
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/home/appuser/.local/bin:$PATH
WORKDIR /app

# Copy Python deps from builder
COPY --from=builder /install /usr/local

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*

# Create non-root user and group before copying code
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy application code with proper ownership
COPY --chown=appuser:appuser . .

USER appuser
EXPOSE 5000

# Healthcheck using curl per best practices guide
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -fsS http://127.0.0.1:5000/ || exit 1

LABEL org.opencontainers.image.description="Secure Python app image (non-root, minimal, no secrets)"

CMD ["python", "app.py"]
