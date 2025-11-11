from fastapi import FastAPI
from pydantic import BaseModel
import os, socket, time

app = FastAPI(title="demo-microservice")

class Health(BaseModel):
    status: str
    host: str
    timestamp: float

@app.get("/")
def root():
    return {"message": "Hello from AKS!", "host": socket.gethostname()}

@app.get("/healthz", response_model=Health)
def healthz():
    return Health(status="ok", host=socket.gethostname(), timestamp=time.time())
