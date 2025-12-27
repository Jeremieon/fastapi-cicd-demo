from fastapi import FastAPI, HTTPException
from config import settings

import time

app = FastAPI(title=settings.app_name, version=settings.version)
deployment_time = time.time()


@app.get("/")
def read_root():
    return {
        "message": f"Hello from CI/CD v{settings.version}!",
        "environment": settings.environment,
        "status": "running",
    }


@app.get("/health")
def health_check():
    """Health check endpoint for deployment verification Banger"""
    return {
        "status": "healthy",
        "environment": settings.environment,
        "version": settings.version,
        "uptime": int(time.time() - deployment_time),
    }


@app.get("/api/info")
def get_info():
    return settings.get_info()


@app.get("/api/test-error")
def test_error():
    """Endpoint to test rollback - uncomment to simulate failure"""
    return {"message": "No error - endpoint working fine"}


@app.get("/api/data")
def get_data():
    sample_data = {
        "items": [
            {"id": 1, "name": "Item One"},
            {"id": 2, "name": "Item Two"},
            {"id": 3, "name": "Item Three"},
        ]
    }
    return sample_data
