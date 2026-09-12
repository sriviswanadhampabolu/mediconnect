import hashlib
import secrets

def hash_password(password: str) -> str:
    """
    Hash a password using PBKDF2-HMAC-SHA256 with a unique random salt.
    Format: salt$hex_hash
    """
    if not password:
        return ""
    salt = secrets.token_hex(16)
    key = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 100000)
    return f"{salt}${key.hex()}"

def verify_password(stored_hash: str, password: str) -> bool:
    """
    Verify a password against a stored PBKDF2-HMAC-SHA256 hash.
    """
    if not stored_hash or not password or "$" not in stored_hash:
        return False
    try:
        salt, key = stored_hash.split("$", 1)
        test_key = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 100000)
        return secrets.compare_digest(key, test_key.hex())
    except Exception:
        return False
