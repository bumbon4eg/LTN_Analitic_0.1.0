from typing import Sequence

from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.postgresql import insert

from core.db.models import OrderEventModel
from shared.logging.logger import logger


class OrderEventRepository:
    async def add(
        self,
        data: Sequence[OrderEventModel],
        session: AsyncSession,
    ) -> None:
        if not data:
            return

        values = [
            {
                "event_id": event.event_id,
                "order_id": event.order_id,
                "type": event.type,
                "tick": event.tick,
                "from_station": event.from_station,
                "to_station": event.to_station,
                "train_data": event.train_data,
                "is_cargo_empty": event.is_cargo_empty,
            }
            for event in data
        ]

        stmt = (
            insert(OrderEventModel)
            .values(values)
            .on_conflict_do_nothing()
        )

        await session.execute(stmt)

    