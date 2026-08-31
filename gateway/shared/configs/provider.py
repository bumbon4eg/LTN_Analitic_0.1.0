from shared.configs.config_io import load_config
from shared.configs.models import AppConfig
from shared.logging.logger import logger


class ConfigProvider:
    _instance: AppConfig | None = None

    @classmethod
    def get(cls) -> AppConfig:
        if cls._instance is None:
            cls._instance = load_config()
            logger.info("[CFG] initialized")
        return cls._instance

    @classmethod
    def reset(cls):
        cls._instance = None