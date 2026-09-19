"""
MediConnect Root Entrypoint
Enables hosting platforms (Render, Heroku, Railway) to launch using either
`backend.main:app` or `main:app`.
"""
import sys
from pathlib import Path

_root_dir = Path(__file__).resolve().parent
_backend_dir = _root_dir / "backend"

for _path in [str(_root_dir), str(_backend_dir)]:
    if _path not in sys.path:
        sys.path.insert(0, _path)

from backend.main import app

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
