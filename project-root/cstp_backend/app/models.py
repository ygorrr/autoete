# app/models.py

from datetime import datetime
from typing import Dict, Optional

from pydantic import BaseModel, Field


class MeasurementPayload(BaseModel):
    plant_id: str = Field(..., example="CSTP-01")
    timestamp: datetime = Field(..., example="2025-11-15T12:00:00Z")
    measurements: Dict[str, float] = Field(
        ..., example={"DO": 1.8, "S": 120.0}
    )
    setpoints: Dict[str, float] = Field(
        ..., example={"DO": 2.0}
    )


class ControlCommands(BaseModel):
    plant_id: str
    timestamp: datetime
    commands: Dict[str, float] = Field(
        ..., example={"blower_u": 0.65}
    )
    meta: Optional[Dict[str, str]] = Field(
        default=None,
        example={"controller": "PI_DO_v1", "status": "OK"},
    )


class AckResponse(BaseModel):
    status: str = "OK"
    message: str = "Measurement processed"
    control: Optional[ControlCommands] = None
