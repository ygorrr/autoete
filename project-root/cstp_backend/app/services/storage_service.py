# app/services/storage_service.py

from app.models import MeasurementPayload, ControlCommands


async def store_measurement(payload: MeasurementPayload) -> None:
    """
    Persist measurement to DB.
    For now, this is a stub (print or log).
    """
    # TODO: implement real DB logic
    # Example: insert into measurements table
    print(f"[DB] store_measurement: {payload.plant_id} @ {payload.timestamp}")


async def store_control_commands(commands: ControlCommands) -> None:
    """
    Persist control commands to DB.
    """
    # TODO: implement real DB logic
    print(f"[DB] store_control_commands: {commands.plant_id} @ {commands.timestamp}")
