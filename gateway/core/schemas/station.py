from datetime import datetime


from pydantic import BaseModel, Field


class StationSchema(BaseModel):
    id: int = Field(
        ...,
        description="External station ID from game",
    )

    name: str = Field(
        ...,
        description="External station name from game",
    )

    position: tuple[float, float] = Field(
        ...,
        description="Station position (x, y)",
        examples=[
            (33.13, 12.67),
            (11.57, 19.41),
        ],
    )

    planet: str = Field(
        ...,
        description="Planet where this station exists",
    )