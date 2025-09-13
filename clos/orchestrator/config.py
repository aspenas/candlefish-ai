"""Configuration management for CLOS orchestrator."""

import os
from typing import Optional, Dict, Any
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, validator


class Settings(BaseSettings):
    """Application settings."""
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )
    
    # Application
    app_name: str = "CLOS Orchestrator"
    app_version: str = "1.0.0"
    environment: str = Field(default="development", env="ENVIRONMENT")
    debug: bool = Field(default=False, env="DEBUG")
    secret_key: str = Field(..., env="SECRET_KEY")
    jwt_secret: str = Field(..., env="JWT_SECRET")
    jwt_algorithm: str = "HS256"
    jwt_expiration_minutes: int = 30
    
    # Server
    host: str = Field(default="0.0.0.0", env="CLOS_HOST")
    port: int = Field(default=8000, env="CLOS_PORT")
    workers: int = Field(default=4, env="CLOS_WORKERS")
    reload: bool = Field(default=False, env="CLOS_RELOAD")
    
    # Database
    database_url: str = Field(..., env="DATABASE_URL")
    database_pool_size: int = Field(default=20, env="DB_POOL_SIZE")
    database_max_overflow: int = Field(default=40, env="DB_MAX_OVERFLOW")
    database_pool_timeout: int = Field(default=30, env="DB_POOL_TIMEOUT")
    database_echo: bool = Field(default=False, env="DB_ECHO")
    
    # Redis
    redis_url: str = Field(..., env="REDIS_URL")
    redis_pool_size: int = Field(default=10, env="REDIS_POOL_SIZE")
    redis_decode_responses: bool = True
    
    # AWS
    aws_region: str = Field(default="us-east-1", env="AWS_REGION")
    aws_account_id: Optional[str] = Field(default=None, env="AWS_ACCOUNT_ID")
    aws_access_key_id: Optional[str] = Field(default=None, env="AWS_ACCESS_KEY_ID")
    aws_secret_access_key: Optional[str] = Field(default=None, env="AWS_SECRET_ACCESS_KEY")
    aws_endpoint_url: Optional[str] = Field(default=None, env="AWS_ENDPOINT_URL")
    
    # S3
    s3_bucket_assets: str = Field(default="candlefish-assets", env="S3_BUCKET_ASSETS")
    s3_bucket_backups: str = Field(default="candlefish-backups", env="S3_BUCKET_BACKUPS")
    
    # AI Services
    anthropic_api_key: Optional[str] = Field(default=None, env="ANTHROPIC_API_KEY")
    openai_api_key: Optional[str] = Field(default=None, env="OPENAI_API_KEY")
    
    # Agent Configuration
    agent_timeout: int = Field(default=300, env="AGENT_TIMEOUT")
    agent_max_retries: int = Field(default=3, env="AGENT_MAX_RETRIES")
    agent_retry_delay: int = Field(default=5, env="AGENT_RETRY_DELAY")
    
    # Monitoring
    new_relic_license_key: Optional[str] = Field(default=None, env="NEW_RELIC_LICENSE_KEY")
    new_relic_app_name: str = Field(default="CLOS Orchestrator", env="NEW_RELIC_APP_NAME")
    datadog_api_key: Optional[str] = Field(default=None, env="DATADOG_API_KEY")
    sentry_dsn: Optional[str] = Field(default=None, env="SENTRY_DSN")
    
    # Feature Flags
    enable_agent_logging: bool = Field(default=True, env="ENABLE_AGENT_LOGGING")
    enable_performance_monitoring: bool = Field(default=False, env="ENABLE_PERFORMANCE_MONITORING")
    enable_rate_limiting: bool = Field(default=True, env="ENABLE_RATE_LIMITING")
    
    # Rate Limiting
    rate_limit_requests: int = Field(default=100, env="RATE_LIMIT_REQUESTS")
    rate_limit_period: int = Field(default=60, env="RATE_LIMIT_PERIOD")
    
    # CORS
    cors_origins: list[str] = Field(
        default=["http://localhost:3000", "http://localhost:8000"],
        env="CORS_ORIGINS"
    )
    cors_allow_credentials: bool = True
    cors_allow_methods: list[str] = ["*"]
    cors_allow_headers: list[str] = ["*"]
    
    @validator("cors_origins", pre=True)
    def parse_cors_origins(cls, v):
        if isinstance(v, str):
            return v.split(",")
        return v
    
    @validator("database_url")
    def validate_database_url(cls, v):
        if not v.startswith(("postgresql://", "postgres://")):
            raise ValueError("Database URL must be a PostgreSQL connection string")
        return v
    
    @validator("redis_url")
    def validate_redis_url(cls, v):
        if not v.startswith("redis://"):
            raise ValueError("Redis URL must start with redis://")
        return v
    
    @property
    def is_production(self) -> bool:
        """Check if running in production environment."""
        return self.environment == "production"
    
    @property
    def is_development(self) -> bool:
        """Check if running in development environment."""
        return self.environment == "development"
    
    @property
    def is_testing(self) -> bool:
        """Check if running in testing environment."""
        return self.environment == "testing"
    
    def get_aws_config(self) -> Dict[str, Any]:
        """Get AWS configuration."""
        config = {"region_name": self.aws_region}
        
        if self.aws_access_key_id and self.aws_secret_access_key:
            config["aws_access_key_id"] = self.aws_access_key_id
            config["aws_secret_access_key"] = self.aws_secret_access_key
        
        if self.aws_endpoint_url:
            config["endpoint_url"] = self.aws_endpoint_url
        
        return config
    
    def get_database_config(self) -> Dict[str, Any]:
        """Get database configuration for SQLAlchemy."""
        return {
            "pool_size": self.database_pool_size,
            "max_overflow": self.database_max_overflow,
            "pool_timeout": self.database_pool_timeout,
            "echo": self.database_echo,
            "pool_pre_ping": True,
            "pool_recycle": 3600,
        }


# Create global settings instance
settings = Settings()