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

    async def get_order_id_map(
        self, 
        order_ids: list[int], 
        session: AsyncSession
    ) -> dict[int, int]:
        if not order_ids:
            return {}
            
        stmt = select(OrderModel.order_id, OrderModel.id).where(
            OrderModel.order_id.in_(order_ids)
        )
        result = await session.execute(stmt)
        return dict(result.tuples().all())