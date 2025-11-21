# app/config.py

from pydantic import AnyHttpUrl
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # URL of the Julia control service
    JULIA_CONTROL_URL: AnyHttpUrl = "http://localhost:8001/control/do_pi"

    # Pydantic v2 style configuration
    model_config = SettingsConfigDict(
        env_file=".env",      # load from .env if present
        extra="ignore",       # ignore unexpected env vars
    )


settings = Settings()
