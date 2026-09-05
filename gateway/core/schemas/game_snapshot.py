from typing import Sequence

from pydantic import BaseModel, Field

from core.schemas import (
        OrderSchema, 
        OrderEventSchema, 
        TrainSchema, 
        StationSchema
    )

class GameSnapshotSchema(BaseModel):
    protocol_version: str = Field(
        ...,
        description="Protocol schema version",
        examples=[
            "1.0.7",
            "beta 1.3.3"
        ]
    )

    world_id: str = Field(
        ...,
        description="World id"
    )
    sequence_number: int = Field(
        ...,
        description="Snapshot sequence number in dump"
    )
    tick: int = Field(
        ...,
        description="Game ticks"
    )

    active_orders: Sequence[OrderSchema] = Field(
        ...,
        description="Current active orders"
    )

    order_events: Sequence[OrderEventSchema] = Field(
        ...,
        description="Order events"
    )

    trains: dict[int, TrainSchema] = Field(
        ...,
        description="Train data sequece",
        examples=[
            {
                "27": {
                    "id": 27,
                    "length": "1-1-0",
                    "composition_summary": {
                        "omega-cargo-wagon": {
                            "count": 1,
                            "content": {}
                        }
                    },
                    "fuel": [
                        {
                            "type": "wood",
                            "count": 194
                        }
                    ],
                    "name": "Tomas Roll Krognes",
                    "planet": "nauvis"
                },
            }
        ]
    )

    stations: dict[int, StationSchema] = Field(
        ...,
        description="Station data sequece"
    )
