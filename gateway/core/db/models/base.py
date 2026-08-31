import uuid
from datetime import datetime
from typing import Any

from sqlalchemy.orm import DeclarativeBase



def generate_key_name():
    return uuid.uuid4().hex[:16]

class Base(DeclarativeBase):
    def to_dict(self) -> dict:
        return {
            column.name: getattr(self, column.name)
            for column in self.__table__.columns
        }
    
    @classmethod
    def is_editable(cls, field: Any) -> bool:
        editable = getattr(cls, "__editable__", None)
        if editable is None:
            raise AttributeError(f"[SCHEMA] - {cls.__name__} does not define __editable__")

        field_name = getattr(field, "value", field)

        return field_name in editable

    def format_datetime(self, field_name: str, fmt: str = "%d-%m-%Y %H:%M:%S%z") -> str | None:
        """Форматирует указанное поле даты в строку."""
        dt = getattr(self, field_name, None)
        if isinstance(dt, datetime):
            return dt.strftime(fmt)
        return None