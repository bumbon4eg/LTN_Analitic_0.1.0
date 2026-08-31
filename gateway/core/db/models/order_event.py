from datetime import datetime

from sqlalchemy import UUID, BigInteger, Enum, ForeignKey, String, Boolean, JSON, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column

from core.enums import OrderEventType
from core.schemas import TrainSchema
from core.db.models.base import Base



class OrderEventModel(Base):
    __tablename__ = "order_events"
    __editable__ = {}

    id: Mapped[int] = mapped_column(
        BigInteger,
        primary_key=True,
        autoincrement=True,
        comment="Internal event ID",
    )

    event_id: Mapped[UUID] = mapped_column(
        UUID,
        nullable=False,
        unique=True,
        comment="Unique event ID",
    )


    order_id: Mapped[str] = mapped_column(
        String,
        ForeignKey("orders.order_id"),
        nullable=False,
        index=True,
        comment="Order ID associated with this action",
    )

    type: Mapped[OrderEventType] = mapped_column(
        Enum(OrderEventType, name="event_type"),
        default=OrderEventType.CREATE,
        nullable=False,
        comment=(
            "Event type. May be "
            "CREATE/ACCEPT/ERROR/REASSIGNED/COMPLETE"
        ),
    )

    tick: Mapped[int] = mapped_column(
        BigInteger,
        nullable=False,
        comment="Game tick at event started",
    )

    from_station: Mapped[dict] = mapped_column(
        JSON,
        nullable=False,
        comment="Departure station data",
    ) 

    to_station: Mapped[dict] = mapped_column(
        JSON,
        nullable=False,
        comment="Arrival station data",
    )

    train_data: Mapped[dict] = mapped_column(
        JSON,
        nullable=False,
        comment="Train data at event moment",
    )
    
    is_cargo_empty: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        comment="Whether the train was empty at the event moment",
    )