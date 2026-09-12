from shared.configuration.settings.db import DBSettings

from shared.configuration.app import AppConfiguration



def load_config() -> AppConfiguration:
    db_settings = DBSettings() # Attention: This will load the DBSettings from environment variables or .env file

    return AppConfiguration(
        db_settings=db_settings
    )