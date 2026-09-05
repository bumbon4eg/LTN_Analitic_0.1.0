from uuid import UUID

from pydantic import BaseModel, Field

from core.schemas.train import TrainSchema

class OrderSchema(BaseModel):
    id: int = Field(
        ...,
        description="Order ID from LTN",
    )

    train_data: TrainSchema = Field(
            ...,
            description="Train data at create order",
    )

    created_tick: int = Field(
        ...,
        description="Game ticks at order creation",
    )

    network_id: int = Field(
        ...,
        description="LTN network id",
    )

    current_cargo: list[dict] | list = Field(
        ...,
        description="Train current cargo",
    )

    requested_cargo: list[dict] = Field(
        ...,
        description="LTN requested cargo",
    )