#!/usr/bin/env julia

module VirtualCSTPService

using HTTP
using JSON3
using Dates
using Logging

const CORS_HEADERS = [
    "Content-Type" => "application/json",
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Headers" => "*",
    "Access-Control-Allow-Methods" => "GET,POST,OPTIONS",
]

const CORS_PREFLIGHT_HEADERS = [
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Headers" => "*",
    "Access-Control-Allow-Methods" => "GET,POST,OPTIONS",
]


# Adjust this include path if needed
include("VirtualCSTP.jl")
using .VirtualCSTP

# ------------------------------------------------------------------
# Global state
# ------------------------------------------------------------------

const CONTROLLER_STATE = Dict{String, VirtualCSTP.ControlState}()
const LAST_TIMESTAMP   = Dict{String, DateTime}()

const DEFAULT_PI = VirtualCSTP.PIParams(0.8, 0.2)
const DEFAULT_DT_CTRL_S = 10.0
const DEFAULT_DT_CTRL_H = DEFAULT_DT_CTRL_S / 3600.0

const INFER_DT_FROM_TS = true

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

function get_or_init_controller_state(plant_id::AbstractString)
    if haskey(CONTROLLER_STATE, plant_id)
        return CONTROLLER_STATE[plant_id]
    else
        ctrl_state = VirtualCSTP.ControlState(0.5, 0.0)
        CONTROLLER_STATE[plant_id] = ctrl_state
        return ctrl_state
    end
end

"""
    infer_dt_ctrl_h(plant_id, ts; default) -> (dt_h, inferred)

Infer control interval in hours from successive timestamps for each plant.
"""
function infer_dt_ctrl_h(plant_id::AbstractString,
                         ts::DateTime;
                         default::Float64 = DEFAULT_DT_CTRL_H)

    if haskey(LAST_TIMESTAMP, plant_id)
        Δt = ts - LAST_TIMESTAMP[plant_id]
        Δt_ms = Dates.value(Δt)  # Milliseconds as Int64
        if Δt_ms > 0
            Δt_s = Δt_ms / 1000.0
            dt_h = Δt_s / 3600.0
            LAST_TIMESTAMP[plant_id] = ts
            return dt_h, true
        else
            LAST_TIMESTAMP[plant_id] = ts
            return default, false
        end
    else
        LAST_TIMESTAMP[plant_id] = ts
        return default, false
    end
end

# Robust timestamp parsing; accepts ISO-style with or without "Z"
function parse_timestamp(raw::String)::DateTime
    if isempty(raw)
        return now(UTC)
    end
    # try ISO with Z at end
    try
        fmt = dateformat"yyyy-mm-ddTHH:MM:SSZ"
        return DateTime(raw, fmt)
    catch
        # try plain ISO without Z (strip trailing Z if present)
        try
            fmt2 = dateformat"yyyy-mm-ddTHH:MM:SS"
            raw2 = replace(raw, 'Z' => "")
            return DateTime(raw2, fmt2)
        catch
            @warn "Failed to parse timestamp, using now(UTC)" raw_timestamp=raw
            return now(UTC)
        end
    end
end

# Build JSON HTTP response (status, headers, body)
# function json_response(status::Int, obj) :: HTTP.Response
#     body = JSON3.write(obj)
#     return HTTP.Response(
#         status,
#         ["Content-Type" => "application/json"],
#         body,
#     )
# end

function json_response(status::Int, obj)::HTTP.Response
    body = JSON3.write(obj)
    return HTTP.Response(
        status,
        CORS_HEADERS,
        body,
    )
end

function cors_preflight_response()::HTTP.Response
    return HTTP.Response(
        204,                     # No Content
        CORS_PREFLIGHT_HEADERS,
        "",
    )
end



# ------------------------------------------------------------------
# Handlers
# ------------------------------------------------------------------

function handle_health(req::HTTP.Request)
    @info "GET /health"
    return json_response(200, Dict("status" => "ok",
                                   "service" => "VirtualCSTPService"))
end

"""
    handle_do_pi(req) -> HTTP.Response

POST /control/do_pi
Request JSON:
{
  "plant_id": "CSTP-01",
  "timestamp": "2025-11-15T12:00:00Z",
  "measurements": { "DO": 1.8 },
  "setpoints": { "DO": 2.0 }
}
"""
function handle_do_pi(req::HTTP.Request)
    try
        # ------------- parse body -------------
        if req.body === nothing || isempty(req.body)
            return json_response(400, Dict("error" => "Empty request body"))
        end

        raw_body = String(req.body)
        data = JSON3.read(raw_body)

        # plant_id
        haskey(data, "plant_id") || return json_response(400, Dict("error" => "Missing 'plant_id'"))
        plant_id = String(data["plant_id"])

        # timestamp
        raw_ts_str = haskey(data, "timestamp") ? String(data["timestamp"]) : ""
        ts = parse_timestamp(raw_ts_str)
        timestamp_str = string(ts)

        # measurements
        haskey(data, "measurements") || return json_response(400, Dict("error" => "Missing 'measurements' object"))
        meas_obj = data["measurements"]
        haskey(meas_obj, "DO") || return json_response(400, Dict("error" => "Missing 'measurements.DO'"))
        DO_meas = Float64(meas_obj["DO"])

        # setpoints
        haskey(data, "setpoints") || return json_response(400, Dict("error" => "Missing 'setpoints' object"))
        sp_obj = data["setpoints"]
        haskey(sp_obj, "DO") || return json_response(400, Dict("error" => "Missing 'setpoints.DO'"))
        DO_sp = Float64(sp_obj["DO"])

        # ------------- controller logic -------------
        ctrl_state = get_or_init_controller_state(plant_id)
        setpoints = VirtualCSTP.Setpoints(DO_sp)
        pi = DEFAULT_PI

        # default dt, maybe override by inference
        dt_ctrl_h = DEFAULT_DT_CTRL_H
        inferred = false
        if INFER_DT_FROM_TS
            dt_ctrl_h, inferred = infer_dt_ctrl_h(plant_id, ts; default = DEFAULT_DT_CTRL_H)
        end

        meas = (DO = DO_meas,)

        u = VirtualCSTP.update_controller!(ctrl_state, meas, setpoints, pi, dt_ctrl_h)

        # ------------- logging -------------
        @info "PI control step" plant_id=plant_id DO_meas=DO_meas DO_sp=DO_sp u=u dt_ctrl_h=dt_ctrl_h inferred_dt=inferred

        # ------------- response -------------
        response_obj = Dict(
            "plant_id"  => plant_id,
            "timestamp" => timestamp_str,
            "commands"  => Dict("blower_u" => u),
            "meta"      => Dict(
                "controller"  => "PI_DO_v1",
                "status"      => "OK",
                "dt_ctrl_h"   => dt_ctrl_h,
                "dt_inferred" => inferred,
            ),
        )

        return json_response(200, response_obj)

    catch e
        bt = catch_backtrace()
        @error "Exception in handle_do_pi" exception=(e, bt)

        return json_response(
            500,
            Dict(
                "error"   => "Internal server error in handle_do_pi",
                "message" => string(e),
            ),
        )
    end
end

# ------------------------------------------------------------------
# Router & server
# ------------------------------------------------------------------

# function router(req::HTTP.Request)
#     uri = HTTP.URI(req.target)
#     path = String(uri.path)

#     if req.method == "GET" && path == "/health"
#         return handle_health(req)
#     elseif req.method == "POST" && path == "/control/do_pi"
#         return handle_do_pi(req)
#     else
#         return json_response(404, Dict("error" => "Not found", "path" => path))
#     end
# end


function router(req::HTTP.Request)
    uri = HTTP.URI(req.target)
    path = String(uri.path)

    # CORS preflight for any path
    if req.method == "OPTIONS"
        return cors_preflight_response()
    end

    if req.method == "GET" && path == "/health"
        return handle_health(req)
    elseif req.method == "POST" && path == "/control/do_pi"
        return handle_do_pi(req)
    else
        return json_response(404, Dict("error" => "Not found", "path" => path))
    end
end


function main(; host::AbstractString = "0.0.0.0", port::Int = 8001)
    println("Starting VirtualCSTPService on http://$host:$port ...")
    HTTP.serve(router, host, port; verbose = false)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end # module
