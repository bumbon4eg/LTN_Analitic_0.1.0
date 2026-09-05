from datetime import datetime, timedelta, timezone

from sqlalchemy import UUID, BigInteger, ForeignKey, String, Boolean, JSON, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column, relationship, validates

from core.db.models.base import Base
from core.schemas.train import TrainSchema


class OrderModel(Base):
    __tablename__ = "orders"
    __editable__ = {}

    id: Mapped[int] = mapped_column(
        BigInteger,
        primary_key=True,
        autoincrement=True,
        comment="Internal order ID"
    )

    order_id: Mapped[str] = mapped_column(
        String,
        nullable=False,
        unique=True,
        comment="Unique order id, world_id:order_id format"
    )

    train_data: Mapped[dict] = mapped_column(
        JSON,
        nullable=False,
        comment="Train data, on create order moment"
    )

    created_tick: Mapped[int] = mapped_column(
        BigInteger,
        nullable=False,
        index=True,
        comment="Game ticks at order creation",
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        comment="Order creation time in game time. Epoch: 0001-01-01",
    )

    network_id: Mapped[int] = mapped_column(
        BigInteger,
        nullable=False,
        comment="LTN network ID, where was create order"
    )

    current_cargo: Mapped[list[dict] | list] = mapped_column(
            JSON,
            nullable=True,
            comment="Current cargo content, updated on order event"
        )
    
    requested_cargo: Mapped[list[dict]] = mapped_column(
        JSON,
        nullable=False,
        comment="Requested cargo"
    )


    @validates("created_tick")
    def _update_created_at(self, key: str, value: int) -> int:
        """
        en: Formated game time, from game ticks to datetime format. Start with 0001-01-01
        """
        seconds = value / 60
        self.created_at = datetime(1, 1, 1) + timedelta(seconds=seconds)
        return value

