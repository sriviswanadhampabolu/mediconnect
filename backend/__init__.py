"""
MediConnect Backend Package
"""
import sys
from pathlib import Path

# Ensure project root is present in sys.path
_pkg_dir = Path(__file__).resolve().parent
_root_dir = _pkg_dir.parent
for _path in [str(_root_dir), str(_pkg_dir)]:
    if _path not in sys.path:
        sys.path.insert(0, _path)
