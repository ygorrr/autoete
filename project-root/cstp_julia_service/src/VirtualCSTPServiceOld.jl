#!/usr/bin/env julia

module VirtualCSTPService

using HTTP
using JSON3
using Dates

# include the existing virtual plant / controller module
# adjust relative path if needed
include("VirtualCSTP.jl")
using .VirtualCSTP

# ------------------------------------------------------------------
# Global in-memory controller state (per plant_id)
# ------------------------------------------------------------------

const CONTROLLER_STATE = Dict{String, VirtualCSTP.ControlState}()

"""
    get_or_init_controller_state(plant_id) -> ControlState

Return the ControlState for a given plant_id, creating a default one if needed.
"""
function get_or_init_controller_state(plant_id::AbstractString)
    if haskey(CONTROLLER_STATE, plant_id)
        return CONTROLLER_STATE[plant_id]
    else
        # default initial control signal and previous error
        ctrl_state = VirtualCSTP.ControlState(0.5, 0.0)
        CONTROLLER_STATE[plant_id] = ctrl_state
        return ctrl_state
    end
end

# ------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------

# Default PI parameters and control interval used by this service
const DEFAULT_PI = VirtualCSTP.PIParams(0.8, 0.2) # Kp, Ki
const DEFAULT_DT_CTRL_S = 10.0                    # [s]
const DEFAULT_DT_CTRL_H = DEFAULT_DT_CTRL_S / 3600.0

# ------------------------------------------------------------------
# Utility: build HTTP JSON response
# ------------------------------------------------------------------

function json_response(status::Int, obj) :: HTTP.Response
    body = JSON3.write(obj)
    return HTTP.Response(
        status,
        body,
        ["Content-Type" => "application/json"]
    )
end

# ------------------------------------------------------------------
# Handler for /control/do_pi (POST)
# ------------------------------------------------------------------

"""
    handle_do_pi(req) -> HTTP.Response

Expected request JSON:
{
  "plant_id": "CSTP-01",
  "timestamp": "2025-11-15T12:00:00Z",
  "measurements": { "DO": 1.8, "S": 120.0 },
  "setpoints": { "DO": 2.0 }
}

Response JSON:
{
  "plant_id": "CSTP-01",
  "timestamp": "2025-11-15T12:00:00Z",
  "commands": { "blower_u": 0.65 },
  "meta": { "controller": "PI_DO_v1", "status": "OK" }
}
"""
function handle_do_pi(req::HTTP.Request)
    # parse body
    if req.body === nothing || isempty(req.body)
        return json_response(400, (; error = "Empty request body"))
    end

    data = JSON3.read(String(req.body))

    # --- extract fields ---
    # plant_id
    if !haskey(data, "plant_id")
        return json_response(400, (; error = "Missing 'plant_id'"))
    end
    plant_id = String(data["plant_id"])

    # timestamp (optional: echo back; if missing, use now)
    timestamp_str = haskey(data, "timestamp") ? String(data["timestamp"]) : string(Dates.now(Dates.UTC))

    # measurements
    if !haskey(data, "measurements")
        return json_response(400, (; error = "Missing 'measurements' object"))
    end
    meas_obj = data["measurements"]
    if !haskey(meas_obj, "DO")
        return json_response(400, (; error = "Missing 'measurements.DO'"))
    end
    DO_meas = Float64(meas_obj["DO"])

    # setpoints
    if !haskey(data, "setpoints")
        return json_response(400, (; error = "Missing 'setpoints' object"))
    end
    sp_obj = data["setpoints"]
    if !haskey(sp_obj, "DO")
        return json_response(400, (; error = "Missing 'setpoints.DO'"))
    end
    DO_sp = Float64(sp_obj["DO"])

    # --- controller logic ---
    ctrl_state = get_or_init_controller_state(plant_id)

    # create structs expected by update_controller!
    setpoints = VirtualCSTP.Setpoints(DO_sp)
    pi = DEFAULT_PI
    dt_ctrl_h = DEFAULT_DT_CTRL_H

    # measurement as NamedTuple with field DO, matching earlier definition
    meas = (DO = DO_meas,)

    # compute new control signal
    u = VirtualCSTP.update_controller!(ctrl_state, meas, setpoints, pi, dt_ctrl_h)

    # --- build response object ---
    response_obj = (
        plant_id = plant_id,
        timestamp = timestamp_str,
        commands = (; blower_u = u),
        meta = (; controller = "PI_DO_v1", status = "OK")
    )

    return json_response(200, response_obj)
end

# ------------------------------------------------------------------
# Request router
# ------------------------------------------------------------------

function router(req::HTTP.Request)
    # Parse target to get path
    uri = HTTP.URI(req.target)
    path = String(uri.path)

    if req.method == "GET" && path == "/health"
            println("GET request /health")
        return json_response(200, (; status = "ok", service = "VirtualCSTPService"))
    elseif req.method == "POST" && path == "/control/do_pi"
        return handle_do_pi(req)
    else
        return json_response(404, (; error = "Not found", path = path))
    end
end

# ------------------------------------------------------------------
# Run server if executed as script
# ------------------------------------------------------------------

function main(; host::AbstractString = "0.0.0.0", port::Int = 8001)
    println("Starting VirtualCSTPService on http://$host:$port ...")
    HTTP.serve(router, host, port; verbose = true)
end

# Allow `julia src/VirtualCSTPService.jl` to start the server
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end # module

# using .VirtualCSTPService

# VirtualCSTPService.main()
