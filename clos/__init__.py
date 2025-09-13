"""
CLOS - Candlefish Operating System
Central orchestration platform for AI-powered applications and services.
"""

__version__ = "1.0.0"
__author__ = "Candlefish AI"
__email__ = "team@candlefish.ai"

from clos.orchestrator.app import create_app
from clos.orchestrator.config import settings

__all__ = ["create_app", "settings", "__version__"]