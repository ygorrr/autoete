module VirtualCSTP

using Random
using DelimitedFiles

# -----------------------------
# Types
# -----------------------------

struct PlantParams
    V::Float64         # m^3
    Q::Float64         # m^3/h
    Sin::Float64       # mg/L
    DOin::Float64      # mg/L
    DOsat::Float64     # mg/L
    kS::Float64        # 1/h
    kO::Float64        # 1/(h * (mg/L))
    kLa_max::Float64   # 1/h
end

mutable struct PlantState
    S::Float64   # mg/L
    DO::Float64  # mg/L
end

mutable struct ControlState
    u::Float64       # last control signal [0,1]
    e_prev::Float64  # previous error
end

struct PIParams
    Kp::Float64
    Ki::Float64
end

struct NoiseConfig
    σ_DO::Float64
end

struct Setpoints
    DO_sp::Float64
end

# -----------------------------
# Plant dynamics
# -----------------------------

"""
    rhs!(dS, dDO, state, u, p)

Compute RHS of the ODEs for the compact STP model.
Units:
- time in hours
- S, Sin in mg/L
- DO in mg/L
- u in [0,1]
"""
function rhs!(dS::Base.RefValue{Float64},
              dDO::Base.RefValue{Float64},
              state::PlantState,
              u::Float64,
              p::PlantParams)

    S  = state.S
    DO = state.DO

    # unpack parameters
    V        = p.V
    Q        = p.Q
    Sin      = p.Sin
    DOin     = p.DOin
    DOsat    = p.DOsat
    kS       = p.kS
    kO       = p.kO
    kLa_max  = p.kLa_max

    # ODEs
    dS[]  = (Q/V) * (Sin - S) - kS * S
    dDO[] = (Q/V) * (DOin - DO) +
            kLa_max * u * (DOsat - DO) -
            kO * S
    return nothing
end

"""
    step_plant!(state, u, p, dt_h)

Advance plant state one step using explicit Euler with step dt_h (in hours).
"""
function step_plant!(state::PlantState,
                     u::Float64,
                     p::PlantParams,
                     dt_h::Float64)

    dS  = Ref(0.0)
    dDO = Ref(0.0)
    rhs!(dS, dDO, state, u, p)

    state.S  += dt_h * dS[]
    state.DO += dt_h * dDO[]

    # enforce non-negative concentrations
    state.S  = max(state.S,  0.0)
    state.DO = max(state.DO, 0.0)

    return nothing
end

# -----------------------------
# Measurement model
# -----------------------------

"""
    measure(state, noise_cfg, rng)

Return noisy measurements from the plant state.
Currently only DO is measured.
"""
function measure(state::PlantState,
                 noise_cfg::NoiseConfig,
                 rng::AbstractRNG)

    DO_meas = state.DO + noise_cfg.σ_DO * randn(rng)
    return (; DO = DO_meas)
end

# -----------------------------
# Controller
# -----------------------------

"""
    update_controller!(ctrl_state, meas, setpoints, pi, dt_ctrl_h)

Discrete-time PI controller (incremental form) for DO.
- ctrl_state.u in [0,1]
"""
function update_controller!(ctrl_state::ControlState,
                            meas,
                            setpoints::Setpoints,
                            pi::PIParams,
                            dt_ctrl_h::Float64)

    DO_sp = setpoints.DO_sp
    DO_meas = meas.DO

    e = DO_sp - DO_meas

    # incremental PI
    Δu = pi.Kp * (e - ctrl_state.e_prev) +
         pi.Ki * dt_ctrl_h * e

    u_new = ctrl_state.u + Δu

    # saturate
    u_new = min(max(u_new, 0.0), 1.0)

    ctrl_state.u = u_new
    ctrl_state.e_prev = e

    return u_new
end

# -----------------------------
# Simulation / logging
# -----------------------------

"""
    simulate_virtual_plant(; kwargs...)

Run closed-loop simulation and return logged data as a matrix and header vector.
"""
function simulate_virtual_plant(; 
        T_sim_h::Float64 = 4.0,          # total simulation time [h]
        dt_model_s::Float64 = 1.0,       # model step [s]
        ctrl_period_s::Float64 = 10.0,   # control / measurement period [s]
        params::PlantParams = PlantParams(10.0, 1.0, 300.0, 0.0, 8.0, 0.05, 0.02, 5.0),
        state0::PlantState = PlantState(300.0, 0.5),
        pi::PIParams = PIParams(0.8, 0.2),
        setpoints::Setpoints = Setpoints(2.0),
        noise_cfg::NoiseConfig = NoiseConfig(0.05),
        rng_seed::Int = 1234
    )

    rng = MersenneTwister(rng_seed)

    # time steps
    dt_model_h = dt_model_s / 3600.0
    ctrl_period_h = ctrl_period_s / 3600.0
    N_steps = Int(round(T_sim_h / dt_model_h))
    ctrl_stride = Int(round(ctrl_period_h / dt_model_h))
    ctrl_stride = max(ctrl_stride, 1)

    state = PlantState(state0.S, state0.DO)
    ctrl_state = ControlState(0.5, 0.0)  # initial u, e_prev

    # logging arrays: columns = [t_h, S, DO, DO_meas, u]
    log = Array{Float64}(undef, N_steps, 5)
    t = 0.0
    u = ctrl_state.u
    meas = measure(state, noise_cfg, rng) # initial measurement

    for k in 1:N_steps
        # control update
        if (k == 1) || (k % ctrl_stride == 0)
            meas = measure(state, noise_cfg, rng)
            u = update_controller!(ctrl_state, meas, setpoints, pi, ctrl_stride * dt_model_h)
        end

        # log before stepping or after stepping: choose convention
        log[k,1] = t
        log[k,2] = state.S
        log[k,3] = state.DO
        log[k,4] = meas.DO
        log[k,5] = u

        # advance plant
        step_plant!(state, u, params, dt_model_h)
        t += dt_model_h
    end

    header = ["t_h", "S_mgL", "DO_true_mgL", "DO_meas_mgL", "u_aeration"]
    return log, header
end

"""
    save_log_csv(filename; kwargs...)

Run simulation and save log as CSV.
"""
function save_log_csv(filename::AbstractString; kwargs...)
    log, header = simulate_virtual_plant(; kwargs...)
    open(filename, "w") do io
        writedlm(io, permutedims(header), ',')
        writedlm(io, log, ',')
    end
    return nothing
end

# -----------------------------
# Simple test (very basic)
# -----------------------------

"""
    quick_sanity_check()

Run a short simulation and print final DO and S.
"""
function quick_sanity_check()
    log, header = simulate_virtual_plant(T_sim_h = 0.5)
    t_final   = log[end, 1]
    S_final   = log[end, 2]
    DO_final  = log[end, 3]
    println("Final time: ", t_final, " h")
    println("Final S: ", S_final, " mg/L")
    println("Final DO: ", DO_final, " mg/L")
    return nothing
end

# Allow running as script
if abspath(PROGRAM_FILE) == @__FILE__
    println("Running quick sanity check for VirtualCSTP...")
    quick_sanity_check()
    save_log_csv("virtual_cstp_log.csv"; T_sim_h = 4.0)
    println("Log saved to virtual_cstp_log.csv")
end

end # module



# log, header = simulate_virtual_plant(;T_sim_h = 40.0) 

# plot(log[:,1],log[:,2])