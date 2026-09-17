import os
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent

class Settings(BaseSettings):
    PROJECT_NAME: str = "MediConnect AI Health Assistant"
    VERSION: str = "1.0.0"
    API_PREFIX: str = "/api"
    
    # Database configuration (defaults to local SQLite, swappable to MySQL or PostgreSQL)
    DATABASE_URL: str = os.getenv("DATABASE_URL", f"sqlite:///{BASE_DIR}/mediconnect.db")
    
    # Medical record encryption key (Fernet 32-url-safe-base64 key)
    # Default fallback key for local dev:
    ENCRYPTION_KEY: str = os.getenv("ENCRYPTION_KEY", "bXlTZWNyZXRNZWRpY2FsRW5jcnlwdGlvbktleTEyMzQ1Ng==")
    
    # Business-model guardrails: Commission capped at 5-10% (Section 7 constraint)
    COMMISSION_RATE: float = 0.065  # 6.5% commission, strictly capped between 0.05 and 0.10
    MIN_COMMISSION_RATE: float = 0.05
    MAX_COMMISSION_RATE: float = 0.10
    
    # Safety default payment limit
    DEFAULT_PAYMENT_LIMIT: float = 1000.0  # Server-side hard limit
    
    # LLM Provider settings
    LLM_PROVIDER: str = os.getenv("LLM_PROVIDER", "hybrid_rule_ai")  # "hybrid_rule_ai", "openai", "gemini", "claude"
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    ANTHROPIC_API_KEY: str = os.getenv("ANTHROPIC_API_KEY", "")
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    
    # Supabase configuration
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")
    SUPABASE_SERVICE_ROLE_KEY: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
    
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()

# Validation guardrail for commission rate
if not (settings.MIN_COMMISSION_RATE <= settings.COMMISSION_RATE <= settings.MAX_COMMISSION_RATE):
    raise ValueError(f"Commission rate {settings.COMMISSION_RATE} violates business rule (must be 5% - 10%)")
