# FLOX Farm Health API

**Name:** Vanitha Mary
**Date Completed:** 05/03/2026

---

## 📌 Project Overview

This project demonstrates a simple health-aware API service with Docker and CI/CD concepts.

It includes:

* A FastAPI application with health endpoints
* A multi-stage Dockerfile
* A Bash health-check automation script
* A Jenkins pipeline for build and deployment simulation

The goal was to show basic DevOps skills including containerization, health monitoring, and automation.

---

## 📦 Deliverables

### 1️⃣ FastAPI Application (app.py)

**Endpoints:**

* `GET /` — Basic service info
* `GET /health` — Liveness endpoint (service running check)
* `GET /ready` — Readiness endpoint (dependency check)

**Design decisions:**

* Health endpoint returns status, version, and timestamp.
* Version is controlled by `APP_VERSION` environment variable.
* UTC timestamps used for consistency.

---

### 2️⃣ Dockerfile

* Multi-stage build to keep the final image small
* Uses `python:3.12-slim`
* Runs as a non-root user for security
* Includes a Docker `HEALTHCHECK`

---

### 3️⃣ Health Check Script (healthcheck.sh)

**Features:**

* Accepts one or more service URLs
* Calls `/health` endpoint
* Validates HTTP 200 and `"status": "healthy"`
* Includes retry logic
* Optional Slack webhook notification
* Returns exit code `1` if any service is unhealthy

**Example:**

```bash
./healthcheck.sh http://localhost:8000
```

---

### 4️⃣ Jenkins Pipeline

**Pipeline stages:**

* Build Docker image
* Test container health
* Push image (main branch only)
* Deploy to Kubernetes
* Post-deployment health check

Secrets (DockerHub & Slack) are stored securely in Jenkins credentials.

---

# 💻 Run Locally (Without Docker)

Follow the steps below to run the application directly on your laptop.

### 1️⃣ Create a Virtual Environment

From the project root directory:

```bash
python -m venv venv
```

---

### 2️⃣ Activate the Virtual Environment

On **Windows**:

```bash
venv\Scripts\activate
```

On **macOS/Linux**:

```bash
source venv/bin/activate
```

---

### 3️⃣ Install Dependencies

```bash
pip install fastapi uvicorn
```

---

### 4️⃣ Run the Application

```bash
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

* `--reload` enables auto-reload during development.
* The app will start on port **8000**.

---

### 5️⃣ Verify the Health Endpoint

Open your browser and visit:

```
http://localhost:8000/health
```

You should see a JSON response similar to:

```json
{"status":"healthy","version":"0.1.0"}
```

---

# 🐳 Build & Run Using Docker

### Build

```bash
docker build -t flox/farm-health-api:0.1.0 .
```

### Run

```bash
docker run -p 8000:8000 flox/farm-health-api:0.1.0
```

### Test

```bash
curl http://localhost:8000/health
```

API docs available at:

```
http://localhost:8000/docs
```

---

# 🧪 Using the Health Check Script

Make executable:

```bash
chmod +x healthcheck.sh
```

Run:

```bash
./healthcheck.sh http://localhost:8000
```

**Exit codes:**

* `0` → All services healthy
* `1` → One or more services unhealthy

---

# 🚀 Improvements With More Time

* Add real database connectivity checks
* Add unit tests
* Add automatic image tagging from Git commit
* Add **SonarQube analysis stage** for code quality checks  
* Add **Aqua / Trivy security scanning stage** for Docker image vulnerability scanning  
* Add **Python lint checks (e.g., flake8 / pylint)** before allowing PR creation or merge  
* Add **manual approval stage for production deployment** to ensure controlled releases  
* Implement **Helm or Kustomize based Kubernetes deployment** for better configuration management and environment-specific deployments

---

# ✅ Summary

This project demonstrates:

* Docker containerization
* Health monitoring
* CI/CD automation
* Basic deployment validation
* Secure credential handling

It reflects practical DevOps fundamentals suitable for a junior-level role.
