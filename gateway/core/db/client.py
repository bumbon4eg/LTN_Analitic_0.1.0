from sqlalchemy import text
from sqlalchemy.engine import URL
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession, AsyncEngine

from core.db.models.base import Base
from shared.configuration.provider import ConfigProvider
from shared.configuration.ssl_settings import get_database_ssl_option
from shared import logger
from core.db.models.base import Base
from core.db.models import OrderORM, OrderEventORM



class DBClient:
    _instance: "DBClient | None" = None

    def __new__(cls) -> "DBClient":
        if cls._instance is None:
            cls._instance = super().__new__(cls)

        return cls._instance

    def __init__(self) -> None:
        if getattr(self, "_initialized", False):
            return

        self._initialized = True

        self.cfg = ConfigProvider.get()
        self.engine: AsyncEngine | None = None
        self._session_factory: (
            async_sessionmaker[AsyncSession] | None
        ) = None

    async def init(self):
        """
        en: Init engine & sessionmaker
        ru: Инициализация engine и sessionmaker
        """
        self.cfg = ConfigProvider.get()
        if self.engine is not None:
            return
        try:
            logger.info("[DB] - 🔁 Try create engine & connecting to db...")

            new_url = URL.create(
                drivername="postgresql+asyncpg",
                username=self.cfg.db_settings.db_user,
                password=self.cfg.db_settings.db_password,
                host=self.cfg.db_settings.db_host,
                port=self.cfg.db_settings.db_port,
                database=self.cfg.db_settings.db_name
            )

            # Версия для pooler
            # engine = create_async_engine(
            #     new_url,
            #     connect_args={
            #         "ssl": ctx,
            #         "command_timeout": 10,
            #         "statement_cache_size": 0,
            #         "max_cached_statement_lifetime": 0,
            #         "server_settings": {
            #             "jit": "off",
            #         }
            #     },
            #     poolclass=NullPool
            # )

            # Версия для direct connection
            engine = create_async_engine(
                new_url,
                echo=False,
                pool_pre_ping=True,
                pool_recycle=300,
                pool_size=5,
                max_overflow=10,
                connect_args={
                    "command_timeout": 10,
                    "ssl": get_database_ssl_option(self.cfg.db_settings.db_ssl),
                    "server_settings": {
                        "jit": "off",
                    },
                },
            )

            self.engine = engine


            async with engine.connect() as conn:
                await conn.execute(text("SELECT 1"))

            for table in Base.metadata.tables.values():
                logger.info(f"[DB] Table: {table.name}")

                for column in table.columns:
                    logger.info(
                        f"[DB]   {column.name}: {column.type}"
                    )

            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)

            logger.info("[DB] - 🧱 Tables checked/created")

            self._session_factory = async_sessionmaker(
                bind=engine,
                expire_on_commit=False,
                class_=AsyncSession,
            )
            logger.info("[DB] - ✅ Connect to db successfully")

        except SQLAlchemyError as err:
            logger.critical(f"[DB] - ❌ Error connecting to db: {err}")
            if self.engine is not None:
                await self.engine.dispose()
            self.engine = None
            self._session_factory = None
            raise ConnectionError(f"Could not connect to the database: {err}") from err

        except Exception as err:
            logger.critical(f"[DB] - ❌ Undefined error: {err}")
            if self.engine is not None:
                await self.engine.dispose()
            self.engine = None
            self._session_factory = None
            raise

    def get_session_factory(self) -> async_sessionmaker:
        if self._session_factory is None:
            raise RuntimeError("[DB] - db was not init. First step call init()")
        return self._session_factory

    async def close(self):
        if self.engine is None:
            return

        await self.engine.dispose()

        self.engine = None
        self._session_factory = None

        logger.info("[DB] - 🔒 Engine & pool connections closed")

