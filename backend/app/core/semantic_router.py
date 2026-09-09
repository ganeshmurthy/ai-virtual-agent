"""
Semantic Router model registration for LlamaStack.
"""

import logging
from typing import Optional

import httpx
from llama_stack_client import LlamaStackClient
from llama_stack_client.lib.agents.agent import Agent

from ..config import settings

logger = logging.getLogger(__name__)


async def register_semantic_router_model() -> Optional[str]:
    """
    Register semantic-router as a model in LlamaStack if enabled.

    Returns:
        Model ID if registration successful, None otherwise.
    """
    if not settings.SEMANTIC_ROUTER_ENABLED:
        logger.info("Semantic router is disabled, skipping model registration")
        return None

    if not settings.LLAMA_STACK_URL:
        logger.warning("LLAMA_STACK_URL not set, cannot register semantic router")
        return None

    try:
        # Check if semantic router endpoint is reachable
        async with httpx.AsyncClient(timeout=5.0) as client:
            try:
                response = await client.get(
                    f"{settings.SEMANTIC_ROUTER_ENDPOINT}/health"
                )
                response.raise_for_status()
                logger.info("Semantic router endpoint is healthy")
            except Exception as e:
                logger.warning(
                    f"Semantic router endpoint not reachable: {e}. "
                    "Continuing anyway - it may come up later."
                )

        # Connect to LlamaStack
        client = LlamaStackClient(base_url=settings.LLAMA_STACK_URL)

        # Check if semantic-router model already exists
        model_id = "semantic-router"
        try:
            existing_models = client.models.list()
            if any(m.identifier == model_id for m in existing_models):
                logger.info(f"Model '{model_id}' already registered in LlamaStack")
                return model_id
        except Exception as e:
            logger.warning(f"Could not list existing models: {e}")

        # Register the model
        logger.info(
            f"Registering semantic router model '{model_id}' "
            f"at {settings.SEMANTIC_ROUTER_ENDPOINT}"
        )

        client.models.register(
            model_id=model_id,
            provider_id="vllm",
            provider_model_id=model_id,
            metadata={
                "description": "Intelligent routing between fast (2B/3B) and smart (8B) models",
                "routing_enabled": True,
                "backend": "envoy+extproc",
            },
        )

        # Verify registration
        models = client.models.list()
        if any(m.identifier == model_id for m in models):
            logger.info(f"Successfully registered semantic router model: {model_id}")
            return model_id
        else:
            logger.error("Model registration appeared to succeed but model not found in list")
            return None

    except Exception as e:
        logger.error(f"Failed to register semantic router model: {e}", exc_info=True)
        return None
