from datetime import datetime

from pydantic import BaseModel, Field, computed_field

from typing import TYPE_CHECKING



from core.db.models.base import Base


from pydantic import BaseModel, Field, computed_field


class TrainSchema(BaseModel):
    id: int = Field(
        ...,
        description="External train ID from game",
    )
    name: str = Field(
        ...,
        description="Train name from game",
    )

    front_loco: int = Field(
        ...,
        description="Count front locomotives",
    )

    fuel: list[dict] = Field(
        ...,
        description="Locomotives fuel content",
        examples=[
            [
                {
                    "type": "rocket-fuel",
                    "count": 50,
                },
                {
                    "type": "nuclear-fuel",
                    "count": 1,
                },
            ]
        ],
    )

    body_wagons: int = Field(
        ...,
        description="Total number of wagons in the train body",
    )

    body_composition: dict = Field(
        ...,
        description=(
            "Aggregated train body composition by wagon type, "
            "including wagon count and total cargo content"
        ),
        examples=[
            {
                "cargo": {
                    "count": 4,
                    "content": {
                        "stone": 1200,
                        "iron-plate": 200,
                        "copper-plate": 57,
                        "copper-ore": 39,
                    },
                }
            },
            {
                "fluid-cargo": {
                    "count": 4,
                    "content": {
                        "water": 50000,
                        "sulfuric-acid": 50000,
                    },
                },
            },
            {
                "artillery-cargo": {
                    "count": 4,
                    "content": {
                        "firearm-magazine": 97,
                    },
                },
            },
            {    
                "cargo": {
                    "count": 4,
                    "content": {
                        "stone": 1200,
                        "iron-plate": 200,
                        "copper-plate": 57,
                        "copper-ore": 39,
                    },
                },
                "fluid-cargo": {
                    "count": 4,
                    "content": {
                        "water": 50000,
                        "sulfuric-acid": 50000,
                    },
                },
            }
        ],
    )

    rear_loco: int = Field(
        ...,
        description="Count rear locomotives",
    )

    @computed_field
    @property
    def train_composition(self) -> str:
        return (
            f"{self.front_loco}-"
            f"{self.body_wagons}-"
            f"{self.rear_loco}"
        )

    planet: str = Field(
        ...,
        description="Planet, where train exists",
    )



