"""
Supabase Client Initializer for MediConnect
Provides direct access to Supabase Client (Auth, Storage, Database, Realtime)
"""
import logging
from typing import Optional
from backend.config import settings

logger = logging.getLogger("mediconnect.supabase")

_supabase_client = None

def get_supabase_client():
    """
    Returns an initialized Supabase Client if SUPABASE_URL and SUPABASE_KEY are provided.
    Returns None with a graceful fallback if credentials are not configured yet.
    """
    global _supabase_client
    if _supabase_client is not None:
        return _supabase_client

    if not settings.SUPABASE_URL or not (settings.SUPABASE_KEY or settings.SUPABASE_SERVICE_ROLE_KEY):
        return None

    try:
        from supabase import create_client, Client
        key_to_use = settings.SUPABASE_SERVICE_ROLE_KEY or settings.SUPABASE_KEY
        _supabase_client = create_client(settings.SUPABASE_URL, key_to_use)
        logger.info("Supabase client initialized successfully")
        return _supabase_client
    except Exception as e:
        logger.warning(f"Could not initialize Supabase client: {e}")
        return None
