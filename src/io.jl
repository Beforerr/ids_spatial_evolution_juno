using Printf
using Discontinuity
using Discontinuity: load
include("trans.jl")
data_path = datadir("05_reporting")

function Discontinuity.load(path, name_cols::Pair{Symbol}...)
    df = load(path)
    insertcols!(df, name_cols...)
    return df
end

function Discontinuity.load(; tau=60, ts=1.00, name="JNO", method="fit", dir=data_path)
    ts_str = @sprintf "ts_%.2fs" ts
    df = load(joinpath(dir, "events.$name.$method.$(ts_str)_tau_$(tau)s.arrow"))
    df.tau .= tau
    df.ts .= ts
    return df
end

function load_tau(tau)
    df = Discontinuity.load(; tau=tau)
    df.label .= "$tau s"
    println("Number of events: ", size(df, 1))
    return df
end

WIND_PATH = "updated_events_Wind_tr=20110825-20160630_method=fit_tau=0:01:00_ts=0:00:00.090909.arrow"
JNO_PATH = "updated_events_JNO_tr=20110825-20160630_method=fit_tau=0:01:00_ts=0:00:01.arrow"

post_process!(df) = df |> calc_rotation_angle! |> Discontinuity.unitize! |> Discontinuity.calc_beta! |> assign_accuracy!

function backwards_comp!(df)
    @rtransform!(df, 
        :"B.vec.before" = [:"B.vec.before.l", :"B.vec.before.m", :"B.vec.before.n"],
        :"B.vec.after" = [:"B.vec.after.l", :"B.vec.after.m", :"B.vec.after.n"],
    )
end

# the MVAB method can achieve acceptable accuracy when either |B|/|B| > 0.05 or ω > 60°. @liuFailuresMinimumVariance2023
function assign_accuracy!(df)
    @transform!(df, 
        :accuracy = (:rotation_angle .> 60) .| (:db_over_b .> 0.05)
    )
end

function filter_low_accuracy(df)
    @chain df begin
        filter(:accuracy => ==(true), _)
    end
end


function load_wind(; path=WIND_PATH)
    df = load(datadir(path), :dataset => "Wind") |> backwards_comp! |> process!
    rename!(df, ["VX (GSE)", "VY (GSE)", "VZ (GSE)"] .=> ["v_x", "v_y", "v_z"])
    Discontinuity.unitize!(df, "SW Vth", u"km/s")
    Discontinuity.calc_T!(df, "SW Vth")
    return df |> post_process!
end

function load_jno(; path=JNO_PATH)
    df = load(datadir(path), :dataset => "Juno") |> process!
    rename!(df, :radial_distance => :r)
    Discontinuity.unitize!(df, "T", u"K")
    return df |> post_process!
end

"""
# Notes

This will remove events that appear in multiple taus datasets. 
However, this may not remove all "duplicates" that may have little duration differences, since "t.d_start", :"t.d_end" are determined by the maximum distance, and they may vary across different taus for one "event".
"""
function load_taus(taus; unique_f=["t.d_start", "t.d_end"])
    @chain begin
        vcat(load_tau.(taus)...)
        sort(:tau)
        unique(unique_f)
    end
end

function test_load()
    j_events_low_fit = load()
    j_events_tau_20_fit = load(tau=20)
    j_events_high_fit = load(ts=0.12)

    # add a label column to the dataframes
    j_events_low_fit.label .= "1 Hz (fit)"
    j_events_high_fit.label .= "8 Hz (fit)"
    j_events_tau_20_fit.label .= "1 Hz, 20s (fit)"

    # filter high time resolution events
    j_events_high_fit = @chain j_events_high_fit begin
        filter(:len => >(240), _)
    end

    # combine the dataframes
    j_events = reduce(vcat, [j_events_low_fit, j_events_high_fit, j_events_tau_20_fit])

    j_events_taus = 60:-10:20 .|> load_tau |> x -> reduce(vcat, x)

    println("Number of events: ", size(j_events, 1))

    j_events_low_der = load(method="derivative")
    j_events_high_der = load(ts=0.12, method="derivative")

    j_events_low_der[!, :label] .= "1 Hz (derivative)"
    j_events_high_der[!, :label] .= "8 Hz (derivative)"
    j_events_der = vcat(j_events_low_der, j_events_high_der, cols=:intersect)
end