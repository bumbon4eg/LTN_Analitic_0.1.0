from typing import Sequence

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.db.client import DBClient
from core.services.base import BaseService
from core.db.models.order import OrderModel

from core.db.repositories.order import OrderRepository


class OrderService(BaseService):
    def __init__(
        self,
        db_client: DBClient,
        order_repository: OrderRepository,
    ) -> None:
        super().__init__(db_client)
        self._order_repository = order_repository

    async def add_order(
            self,
            raw_data: list[OrderModel],
            session: AsyncSession | None = None
    ):
        async with self._get_session(session) as current_session:
            await self._order_repository.add(
                data=raw_data,
                session=current_session,
            )
    async def filter_existing_order_ids(
            self, 
            order_ids: set[str], 
            session: AsyncSession | None = None
        ) -> set[str]:
            async with self._get_session(session) as current_session:
                return await self._order_repository.get_existing_ids(
                    order_ids=order_ids, 
                    session=current_session
                )

