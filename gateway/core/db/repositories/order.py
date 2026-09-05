from typing import Sequence
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.postgresql import insert

from core.db.models import OrderModel
from shared.logging.logger import logger


class OrderRepository:
    async def add(
        self,
        data: Sequence[OrderModel],
        session: AsyncSession,
    ) -> None:
        if not data:
            return

        values = [
            {
                "order_id": order.order_id,
                "train_data": order.train_data,
                "created_tick": order.created_tick,
                "created_at": order.created_at,
                "network_id": order.network_id,
                "current_cargo": order.current_cargo,
                "requested_cargo": order.requested_cargo,
            }
            for order in data
        ]

        stmt = (
            insert(OrderModel)
            .values(values)
            .on_conflict_do_nothing()
        )

        await session.execute(stmt)

    async def get_existing_ids(
        self, 
        order_ids: set[str], 
        session: AsyncSession
    ) -> set[str]:
        """Возвращает подмножество order_ids, которые реально существуют в БД."""
        if not order_ids:
            return set()

        stmt = select(OrderModel.order_id).where(OrderModel.order_id.in_(order_ids))
        result = await session.execute(stmt)
        return set(result.scalars().all())
