# app.py

# Import FastAPI framework
from fastapi import FastAPI

# Used to read environment variables (e.g., APP_VERSION)
import os

# Used to generate UTC timestamp for health response
import datetime


# Create FastAPI application instance
app = FastAPI(title="FLOX Farm Health API")


# ---------------------------------------------------------
# GET /health
# Liveness / Health endpoint
# Used by:
# - Kubernetes livenessProbe
# - Monitoring systems
# - CI/CD health validation
# ---------------------------------------------------------
@app.get("/health")
def health_check():
    return {
        "status": "healthy",  # Indicates service is running
        "service": "farm-health-api",  # Service name
        "version": os.getenv("APP_VERSION", "0.1.0"),  # Version from env (default 0.1.0)
        "timestamp": datetime.datetime.utcnow().isoformat()  # Current UTC time
    }


# ---------------------------------------------------------
# GET /ready
# Readiness endpoint
# Used by:
# - Kubernetes readinessProbe
# - Determines if app is ready to receive traffic
# ---------------------------------------------------------
@app.get("/ready")
def readiness_check():
    return {
        "ready": True,  # Indicates service is ready
        "checks": {
            "database": "ok",  # Placeholder dependency check
            "cache": "ok"      # Placeholder dependency check
        }
    }


# ---------------------------------------------------------
# GET /
# Root endpoint
# Basic information about the service
# ---------------------------------------------------------
@app.get("/")
def root():
    return {
        "message": "FLOX Farm Health API",
        "docs": "/docs"  # Swagger UI documentation endpoint
    }