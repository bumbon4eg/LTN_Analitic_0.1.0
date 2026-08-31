import os
from pathlib import Path
from shared.logging.logger import logger
from typing import List

from pydantic import BaseModel, Field
from typing import Dict
from pydantic_settings import BaseSettings, SettingsConfigDict


BASE_DIR = Path(__file__).resolve().parents[2]
PREVIOUS_DIR = Path(__file__).resolve().parents[3]


class CommonSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=BASE_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=True,
    )


class DBConfig(CommonSettings):
    # db_url: str = Field(..., alias="DB_URL")
    db_user: str = Field(..., alias="DB_USER")
    db_password: str = Field(..., alias="DB_PASSWORD")
    db_host: str = Field(..., alias="DB_HOST")
    db_port: int = Field(..., alias="DB_PORT")
    db_name: str = Field(..., alias="DB_NAME")


class AppConfig(BaseModel):
    base_dir: Path = Field(
        default=BASE_DIR,
        description="Application root directory",
    )

    db_config: DBConfig


