from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

from shared.configuration.constants import BASE_DIR


class CommonSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=BASE_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=True,
    )
