using Printf
using Discontinuity
import Discontinuity: load
data_path = datadir("05_reporting")

function Discontinuity.load(;tau=60, ts=1.00, name="JNO", method="fit", dir=data_path)
    ts_str = @sprintf "ts_%.2fs" ts
    df = Discontinuity.load(joinpath(dir, "events.$name.$method.$(ts_str)_tau_$(tau)s.arrow"))
    df.tau .= tau
    df.ts .= ts
    return df
end

function load_tau(tau)
    df = load(tau=tau)
    df.label .= "$tau s"
    println("Number of events: ", size(df, 1))
    return df
end

"""
## Note

This will remove events that appear in multiple taus datasets. 
However, this may not remove all "duplicates" that may have little duration differences, since "t.d_start", :"t.d_end" are determined by the maximum distance, and they may vary across different taus for one "event".
"""
function load_taus(taus; unique_f = ["t.d_start", "t.d_end"])
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