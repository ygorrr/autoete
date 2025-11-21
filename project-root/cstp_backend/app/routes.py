# app/routes.py

from fastapi import APIRouter, Depends, HTTPException, status
import httpx

from app.models import MeasurementPayload, AckResponse, ControlCommands
from app.services.control_service import request_control_actions
from app.services.storage_service import (
    store_measurement,
    store_control_commands,
)

router = APIRouter(prefix="/api/v1", tags=["cstp"])


async def get_http_client():
    async with httpx.AsyncClient(timeout=5.0) as client:
        yield client


@router.post(
    "/plants/{plant_id}/measurements",
    response_model=AckResponse,
    status_code=status.HTTP_200_OK,
)
async def receive_measurement(
    plant_id: str,
    payload: MeasurementPayload,
    client: httpx.AsyncClient = Depends(get_http_client),
):
    """
    Ingestion endpoint for plant/gateway.

    - payload must have plant_id matching the URL.
    - Stores measurement.
    - Calls Julia control service to compute control actions.
    - Stores and returns control commands.
    """
    if payload.plant_id != plant_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="plant_id in URL and body must match",
        )

    # 1. Store measurement
    await store_measurement(payload)

    # 2. Call Julia service for control commands
    try:
        control: ControlCommands = await request_control_actions(
            payload, client=client
        )
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Error contacting Julia control service: {exc}",
        ) from exc

    # 3. Store control commands
    await store_control_commands(control)

    # 4. Return combined ACK + commands
    return AckResponse(
        status="OK",
        message="Measurement processed and control actions generated",
        control=control,
    )
