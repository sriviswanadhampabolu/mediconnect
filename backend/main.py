import sys
from pathlib import Path

_current_dir = Path(__file__).resolve().parent
_root_dir = _current_dir.parent
for _path in [str(_root_dir), str(_current_dir)]:
    if _path not in sys.path:
        sys.path.insert(0, _path)

from contextlib import asynccontextmanager
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from backend.config import settings
from backend.seed_data import init_db_and_seed
from backend.api.routes_triage import router as triage_router
from backend.api.routes_pharmacy import router as pharmacy_router
from backend.api.routes_records import router as records_router
from backend.api.routes_emergency import router as emergency_router
from backend.api.routes_auth import router as auth_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize DB tables and seed sample data
    init_db_and_seed()
    yield

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="MediConnect AI-Powered Hyperlocal Pharmacy & Health Assistant API with 12 Multi-Agent Orchestration, strict safety vetoes, medical record encryption, and 5-10% capped local pharmacy commissions.",
    lifespan=lifespan
)

# Enable CORS for web simulator and Android dev clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register API routers under /api and /api/v1 for broad client compatibility
for prefix in [settings.API_PREFIX, f"{settings.API_PREFIX}/v1"]:
    app.include_router(auth_router, prefix=prefix)
    app.include_router(triage_router, prefix=prefix)
    app.include_router(pharmacy_router, prefix=prefix)
    app.include_router(records_router, prefix=prefix)
    app.include_router(emergency_router, prefix=prefix)

# Static files for Interactive Web Simulator & Test Console
STATIC_DIR = Path(__file__).resolve().parent / "static"
STATIC_DIR.mkdir(exist_ok=True)

FLUTTER_WEB_DIR = Path(__file__).resolve().parent.parent / "mediconnect_flutter" / "build" / "web"
if FLUTTER_WEB_DIR.exists():
    app.mount("/flutter", StaticFiles(directory=str(FLUTTER_WEB_DIR), html=True), name="flutter")

app.mount("/", StaticFiles(directory=str(STATIC_DIR), html=True), name="static")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.main:app", host="127.0.0.1", port=8000, reload=True)
