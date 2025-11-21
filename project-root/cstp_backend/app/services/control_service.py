# app/services/control_service.py

from typing import Optional

import httpx

from app.config import settings
from app.models import MeasurementPayload, ControlCommands


async def request_control_actions(
    payload: MeasurementPayload,
    client: Optional[httpx.AsyncClient] = None,
) -> ControlCommands:
    """
    Forward measurements + setpoints to Julia control service,
    return parsed ControlCommands.
    """
    # Reuse client if provided (for performance / testing)
    if client is None:
        async with httpx.AsyncClient(timeout=5.0) as local_client:
            return await _request_control_actions_inner(payload, local_client)
    else:
        return await _request_control_actions_inner(payload, client)


async def _request_control_actions_inner(
    payload: MeasurementPayload,
    client: httpx.AsyncClient,
) -> ControlCommands:
    url = str(settings.JULIA_CONTROL_URL)

    response = await client.post(url, json=payload.dict())
    response.raise_for_status()

    data = response.json()
    return ControlCommands(**data)
