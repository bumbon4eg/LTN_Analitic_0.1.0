from pydantic import Field

from shared.configuration.settings.common import CommonSettings


class DBSettings(CommonSettings):
    # db_url: str = Field(..., alias="DB_URL")
    db_user: str = Field(..., alias="DB_USER")
    db_password: str = Field(..., alias="DB_PASSWORD")
    db_host: str = Field(..., alias="DB_HOST")
    db_port: int = Field(..., alias="DB_PORT")
    db_name: str = Field(..., alias="DB_NAME")