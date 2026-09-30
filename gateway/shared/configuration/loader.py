from shared.configuration.settings.db import DBSettings
from shared.configuration.app import AppConfiguration
from shared.configuration.user_config import (
    get_default_source_path,
    load_user_config,
)


def load_config() -> AppConfiguration:
    user_config = load_user_config()
    if user_config is None:
        db_settings = DBSettings()
        source_jsonl_path = get_default_source_path()
    else:
        database = user_config.database
        db_settings = DBSettings(
            DB_USER=database.db_user,
            DB_PASSWORD=database.db_password,
            DB_HOST=database.db_host,
            DB_PORT=database.db_port,
            DB_NAME=database.db_name,
            DB_SSL=database.db_ssl,
        )
        source_jsonl_path = user_config.source_jsonl_path

    return AppConfiguration(
        db_settings=db_settings,
        source_jsonl_path=source_jsonl_path,
    )