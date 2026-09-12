from pathlib import Path

from pydantic import BaseModel, Field

from shared.configuration.constants import BASE_DIR
from shared.configuration.settings.db import DBSettings



class AppConfiguration(BaseModel):
    base_dir: Path = Field(
        default=BASE_DIR,
        description="Application root directory",
    )

    db_settings: DBSettings



