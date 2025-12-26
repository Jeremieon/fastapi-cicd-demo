from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def read_root():
    return {"message": "Hello from CI/CD!", "status": "running"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}


@app.get("/api/info")
def get_info():
    return {"app": "FastAPI CI/CD Demo", "version": "2.0.0"}


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
