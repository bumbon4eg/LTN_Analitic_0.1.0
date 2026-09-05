from enum import Enum


class OrderEventType(Enum):
    CREATED = "created"
    LOADED = "loaded"
    ERROR = "error"
    REASSIGNED = "reassigned"
    COMPLETED = "completed"