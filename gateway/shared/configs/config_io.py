from .models import (
    AppConfig,
    DBConfig,
)


def load_config() -> AppConfig:
    db_config = DBConfig() # type: ignore[call-arg]

    return AppConfig(
        db_config=db_config
    )