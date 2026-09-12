import base64
import json
from typing import Any, List
from cryptography.fernet import Fernet
from backend.config import settings

def _get_fernet_instance() -> Fernet:
    key = settings.ENCRYPTION_KEY.encode()
    # If the key isn't a valid 32-byte url-safe base64 string, derive or pad
    try:
        return Fernet(key)
    except Exception:
        # Fallback to generating a deterministic 32-byte base64 key for local dev
        padded_key = base64.urlsafe_b64encode(key.ljust(32, b'0')[:32])
        return Fernet(padded_key)

_fernet = _get_fernet_instance()

def encrypt_data(data: Any) -> str:
    """Encrypts any Python data structure (dict, list, str) into an encrypted string token."""
    if data is None:
        return ""
    if not isinstance(data, str):
        data_str = json.dumps(data)
    else:
        data_str = data
    return _fernet.encrypt(data_str.encode("utf-8")).decode("utf-8")

def decrypt_data(encrypted_str: str) -> Any:
    """Decrypts an encrypted string token back to raw text or parsed JSON."""
    if not encrypted_str:
        return None
    try:
        decrypted_bytes = _fernet.decrypt(encrypted_str.encode("utf-8"))
        decrypted_str = decrypted_bytes.decode("utf-8")
        try:
            return json.loads(decrypted_str)
        except json.JSONDecodeError:
            return decrypted_str
    except Exception as e:
        return f"[Decryption Error: {str(e)}]"

def encrypt_list(items: List[str]) -> str:
    return encrypt_data(items or [])

def decrypt_list(encrypted_str: str) -> List[str]:
    res = decrypt_data(encrypted_str)
    if isinstance(res, list):
        return res
    if res and isinstance(res, str):
        return [res]
    return []
