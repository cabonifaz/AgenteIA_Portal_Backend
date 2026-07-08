from pydantic_settings import BaseSettings
from pydantic import field_validator, ConfigDict
from typing import Optional
import logging

logger = logging.getLogger(__name__)

class DatabaseConfig(BaseSettings):
    """Database configuration settings"""
    model_config = ConfigDict(
        env_file=".env",
        case_sensitive=False,
        extra="ignore"
    )

    # MySQL Database Configuration
    db_host: str
    db_name: str
    db_user: str
    db_password: str
    db_port: int = 3306
    db_ssl_disabled: bool = False

    @field_validator('db_host')
    @classmethod
    def validate_db_host(cls, v):
        if not v:
            raise ValueError("Database host is required")
        return v

    @field_validator('db_name')
    @classmethod
    def validate_db_name(cls, v):
        if not v:
            raise ValueError("Database name is required")
        return v

    @field_validator('db_user')
    @classmethod
    def validate_db_user(cls, v):
        if not v:
            raise ValueError("Database user is required")
        return v

    @field_validator('db_password')
    @classmethod
    def validate_db_password(cls, v):
        if not v:
            raise ValueError("Database password is required")
        return v

    @property
    def database_url(self) -> str:
        """Generate MySQL connection string"""
        ssl_param = "&ssl_disabled=true" if self.db_ssl_disabled else ""
        return f"mysql+pymysql://{self.db_user}:{self.db_password}@{self.db_host}:{self.db_port}/{self.db_name}?charset=utf8mb4{ssl_param}"

# Create database configuration instance
try:
    database_config = DatabaseConfig()
    logger.info("Database configuration loaded successfully")
except Exception as e:
    logger.error(f"Failed to load database configuration: {e}")
    raise RuntimeError(f"Database configuration validation failed: {str(e)}")