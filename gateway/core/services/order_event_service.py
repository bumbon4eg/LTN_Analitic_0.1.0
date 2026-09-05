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
        order_service
    ) -> None:
        super().__init__(db_client)
        self._order_event_repository = order_event_repository
        self._order_service = order_service

    async def add_order_events(
            self,
            events: list[OrderEventModel],
            session: AsyncSession | None = None,
        ) -> None:
            if not events:
                return

            async with self._get_session(session) as current_session:
                target_ids = {event.order_id for event in events}

                existing_ids = await self._order_service.filter_existing_order_ids(
                    order_ids=target_ids, 
                    session=current_session
                )

                valid_events = [e for e in events if e.order_id in existing_ids]

                if not valid_events:
                    return

                await self._order_event_repository.add(
                    data=valid_events,
                    session=current_session,
                )