import json
import os
from pathlib import Path

from pydantic import BaseModel, Field


def get_app_data_dir() -> Path:
    app_data = os.environ.get("APPDATA")
    if app_data:
        return Path(app_data) / "LTN_Analitics_gateway"
    return Path.home() / "AppData" / "Roaming" / "LTN_Analitics_gateway"


CONFIG_PATH = get_app_data_dir() / "config.conf"


def get_default_source_path() -> Path:
    app_data = os.environ.get("APPDATA")
    roaming_dir = Path(app_data) if app_data else Path.home() / "AppData" / "Roaming"
    return roaming_dir / "Factorio" / "script-output" / "LTN_Analitic" / "data.jsonl"


class DatabaseConfig(BaseModel):
    db_user: str = ""
    db_password: str = ""
    db_host: str = "localhost"
    db_port: int = 5432
    db_name: str = ""
    db_ssl: bool = False


class RunStatistics(BaseModel):
    runs: int = 0
    snapshots_processed: int = 0
    orders_sent: int = 0
    events_sent: int = 0
    last_run_at: str | None = None


class GatewayConfig(BaseModel):
    source_jsonl_path: str = str(get_default_source_path())
    database: DatabaseConfig = Field(default_factory=DatabaseConfig)
    statistics: RunStatistics = Field(default_factory=RunStatistics)


def load_user_config() -> GatewayConfig | None:
    if not CONFIG_PATH.is_file():
        return None
    return GatewayConfig.model_validate_json(CONFIG_PATH.read_text(encoding="utf-8"))


def save_user_config(config: GatewayConfig) -> None:
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = CONFIG_PATH.with_suffix(".conf.tmp")
    temporary_path.write_text(
        json.dumps(config.model_dump(mode="json"), indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    os.replace(temporary_path, CONFIG_PATH)