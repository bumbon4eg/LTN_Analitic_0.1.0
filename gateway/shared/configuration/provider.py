from shared.configuration.loader import load_config
from shared.configuration.app import AppConfiguration
from shared.logging.logger import logger


class ConfigProvider:
    _instance: AppConfiguration | None = None

    @classmethod
    def get(cls) -> AppConfiguration:
        if cls._instance is None:
            cls._instance = load_config()
            logger.info("[CFG] initialized")
        return cls._instance

    @classmethod
    def reset(cls) -> None:
        cls._instance = None