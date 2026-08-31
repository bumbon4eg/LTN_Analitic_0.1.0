from contextlib import asynccontextmanager
from sqlalchemy.ext.asyncio import AsyncSession

from core.db.client import DBClient


class BaseService:
    def __init__(self, db_client: DBClient):
        self._db_client= db_client

    @asynccontextmanager
    async def _get_session(self, session: AsyncSession | None = None):
        """
        ru: Позволяет совершать последовательные действия, находясь внутри одной сессии.
            Поведение: Если сессия была передана как аргумент, возвращает ее же. Если сессия не передана, то используется
            значение по-умолчанию, None, в таком случае создается новая сессия в формате begin -> вызывать begin вручную НЕ НУЖНО.
            Begin вызывается на первом этапе flow и далее передавется по уровням.
        """
        
        if session is not None:
            yield session
        else:
            session_factory = self._db_client.get_session_factory()
            async with session_factory() as new_session:
                async with new_session.begin():
                    yield new_session
