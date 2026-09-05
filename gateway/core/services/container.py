from functools import cached_property

from core.db.client import DBClient
from core.db.repositories.order import OrderRepository
from core.db.repositories.order_event import OrderEventRepository
from core.services.order_event_service import OrderEventService
from core.services.order_service import OrderService

class ServiceContainer:
    def __init__(self, db: DBClient) -> None:
        self._db = db
        self.order_repo = OrderRepository()
        self.order_event_repo = OrderEventRepository()

    @cached_property
    def order_service(self) -> OrderService:
        return OrderService(
            db_client=self._db,
            order_repository=self.order_repo,
        )

    @cached_property
    def order_event_service(self) -> OrderEventService:
        return OrderEventService(
            db_client=self._db,
            order_event_repository=self.order_event_repo,
            order_service=self.order_service
        )