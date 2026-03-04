# -------- Stage 1: Build --------
# Use slim Python image to reduce final size
FROM python:3.12-slim AS builder

# Environment variables:
# VENV_PATH → location of virtual environment
# PYTHONDONTWRITEBYTECODE → prevents creation of .pyc files
# PYTHONUNBUFFERED → ensures logs are flushed immediately (important for Docker logs)
ENV VENV_PATH=/opt/venv \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 

# Create a virtual environment inside the container
# Upgrade pip to latest version
RUN python -m venv ${VENV_PATH} \
    && ${VENV_PATH}/bin/pip install --upgrade pip 

# Install build dependencies (needed for compiling some Python packages)
# Removed after installation to keep image small
RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy dependency file first (improves Docker layer caching)
COPY requirements.txt .

# Install Python dependencies into virtual environment
RUN ${VENV_PATH}/bin/pip install --no-cache-dir -r requirements.txt


# -------- Stage 2: Runtime --------
# Use a fresh slim image to keep runtime lightweight
FROM python:3.12-slim

# Runtime environment variables
# APP_VERSION can be overridden at runtime (e.g., via Kubernetes)
ENV VENV_PATH=/opt/venv \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_VERSION=0.1.0

# Install only curl (used for container healthcheck)
# Avoid installing build tools in runtime image
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for security best practice
# Containers should not run as root in production
RUN useradd -u 10001 -m appuser \
    && mkdir -p /app \
    && chown -R appuser:appuser /app

# Copy the pre-built virtual environment from builder stage
# This avoids reinstalling dependencies in runtime stage
COPY --from=builder ${VENV_PATH} ${VENV_PATH}

# Add virtual environment binaries to PATH
ENV PATH="${VENV_PATH}/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy application source code
COPY app.py /app/

# Expose application port
EXPOSE 8000

# Container-level health check
# Docker will mark container as unhealthy if this fails repeatedly
# Checks /health endpoint for "status": "healthy"
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:8000/health | grep -q '\"status":\s*\"healthy\"' || exit 1

# Switch to non-root user before running application
USER appuser

# Start FastAPI app using Uvicorn ASGI server
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]