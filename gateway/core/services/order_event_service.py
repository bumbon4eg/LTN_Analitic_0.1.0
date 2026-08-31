from sqlalchemy.ext.asyncio import AsyncSession

from core.db.client import DBClient
from core.db.models.order import OrderModel
from core.db.models.order_event import OrderEventModel
from core.db.repositories.order_event import OrderEventRepository
from core.db.repositories.order import OrderRepository

from core.services.base import BaseService
from core.services.order_service import OrderService
from shared.logging.logger import logger


class OrderEventService(BaseService):
    def __init__(
        self,
        db_client: DBClient,
        order_event_repository: OrderEventRepository,
        order_repository: OrderRepository,
    ) -> None:
        super().__init__(db_client)
        self._order_event_repository = order_event_repository
        self._order_repository = order_repository

    async def add_order_events_with_orders(
        self,
        orders: list[OrderModel],
        events: list[OrderEventModel],
        session: AsyncSession | None = None,
    ) -> None:
        async with self._get_session(session) as current_session:
            if orders:
                await self._order_repository.add(
                    orders,
                    session=current_session,
                )

            incoming_order_ids = list({event.order_id for event in events})

            order_id_map = await self._order_repository.get_order_id_map(
                order_ids=incoming_order_ids,
                session=current_session,
            )

            valid_events = [
                event
                for event in events
                if event.order_id in order_id_map
            ]

            if valid_events:
                await self._order_event_repository.add(
                    data=valid_events,
                    session=current_session,
                )