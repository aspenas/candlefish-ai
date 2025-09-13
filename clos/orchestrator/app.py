"""CLOS Orchestrator FastAPI application."""

from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
import structlog
from prometheus_client import make_asgi_app

from clos.orchestrator.config import settings
from clos.orchestrator.database import init_db, close_db
from clos.orchestrator.middleware import (
    LoggingMiddleware,
    RateLimitMiddleware,
    MetricsMiddleware,
)
from clos.orchestrator.routers import (
    health,
    auth,
    agents,
    workflows,
    services,
)
from clos.utils.logging import setup_logging
from clos.utils.monitoring import init_monitoring

# Configure structured logging
logger = structlog.get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """Application lifespan manager."""
    # Startup
    logger.info("Starting CLOS Orchestrator", environment=settings.environment)
    
    # Initialize logging
    setup_logging(settings)
    
    # Initialize monitoring
    if settings.enable_performance_monitoring:
        init_monitoring(settings)
    
    # Initialize database
    await init_db()
    
    # Initialize Redis connection
    from clos.services.cache import init_redis
    await init_redis(settings.redis_url)
    
    # Initialize agent pool
    from clos.services.agent_pool import init_agent_pool
    await init_agent_pool()
    
    logger.info("CLOS Orchestrator started successfully")
    
    yield
    
    # Shutdown
    logger.info("Shutting down CLOS Orchestrator")
    
    # Close database connections
    await close_db()
    
    # Close Redis connections
    from clos.services.cache import close_redis
    await close_redis()
    
    # Shutdown agent pool
    from clos.services.agent_pool import shutdown_agent_pool
    await shutdown_agent_pool()
    
    logger.info("CLOS Orchestrator shutdown complete")


def create_app() -> FastAPI:
    """Create and configure FastAPI application."""
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="Central orchestration platform for AI-powered applications",
        docs_url="/docs" if not settings.is_production else None,
        redoc_url="/redoc" if not settings.is_production else None,
        openapi_url="/openapi.json" if not settings.is_production else None,
        lifespan=lifespan,
    )
    
    # Add CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=settings.cors_allow_credentials,
        allow_methods=settings.cors_allow_methods,
        allow_headers=settings.cors_allow_headers,
    )
    
    # Add trusted host middleware
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=["*"] if settings.is_development else ["*.candlefish.ai", "localhost"],
    )
    
    # Add custom middleware
    app.add_middleware(LoggingMiddleware)
    app.add_middleware(MetricsMiddleware)
    
    if settings.enable_rate_limiting:
        app.add_middleware(
            RateLimitMiddleware,
            requests_per_minute=settings.rate_limit_requests,
        )
    
    # Mount Prometheus metrics endpoint
    metrics_app = make_asgi_app()
    app.mount("/metrics", metrics_app)
    
    # Include routers
    app.include_router(health.router, tags=["health"])
    app.include_router(auth.router, prefix="/api/v1/auth", tags=["authentication"])
    app.include_router(agents.router, prefix="/api/v1/agents", tags=["agents"])
    app.include_router(workflows.router, prefix="/api/v1/workflows", tags=["workflows"])
    app.include_router(services.router, prefix="/api/v1/services", tags=["services"])
    
    # Global exception handler
    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        logger.error(
            "Unhandled exception",
            exc_info=exc,
            path=request.url.path,
            method=request.method,
        )
        
        if settings.is_production:
            return JSONResponse(
                status_code=500,
                content={"detail": "Internal server error"},
            )
        else:
            return JSONResponse(
                status_code=500,
                content={
                    "detail": str(exc),
                    "type": type(exc).__name__,
                },
            )
    
    return app


# Create application instance
app = create_app()

if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "clos.orchestrator.app:app",
        host=settings.host,
        port=settings.port,
        reload=settings.reload,
        workers=settings.workers if not settings.reload else 1,
        log_config={
            "version": 1,
            "disable_existing_loggers": False,
            "formatters": {
                "default": {
                    "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
                },
            },
            "handlers": {
                "default": {
                    "formatter": "default",
                    "class": "logging.StreamHandler",
                    "stream": "ext://sys.stdout",
                },
            },
            "root": {
                "level": "INFO" if settings.is_production else "DEBUG",
                "handlers": ["default"],
            },
        },
    )