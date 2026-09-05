from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field

from core.enums import OrderEventType
from core.schemas import StationSchema, TrainSchema


class OrderEventSchema(BaseModel):
    id: UUID = Field(
        ...,
        description="Unique event ID",
    )

    order_id: int = Field(
            ...,
            description="Order id",
    )

    type: OrderEventType = Field(
            ...,
            description="Event type",
    )

    tick: int = Field(
        ...,
        description="Game tick at event started",
    )

    from_station: StationSchema | dict[str, Any] = Field(
        ...,
        description="Departure station",
    )

    to_station: StationSchema | dict[str, Any] = Field(
            ...,
            description="Arrival station",
    )

    train_data: TrainSchema | dict[str, Any] = Field(
            ...,
            description="Train data at event moment",
    )

    is_cargo_empty: bool = Field(
            ...,
            description="Whether the train was empty at the event moment",
    )

