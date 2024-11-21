using Printf
using Discontinuity
using Discontinuity: load
using Dates
using Dates: AbstractTime
data_path = datadir("05_reporting")

DEFAULT_TAUS = 60:-10:20

post_process!(df) = begin
    df |>
    Discontinuity.keep_good_fit! |>
    Discontinuity.standardize_df! |>
    Discontinuity.compute_params! |>
    Discontinuity.unitize! |>
    Discontinuity.calc_beta! |>
    assign_accuracy!
end

function Discontinuity.load(; tau=60, ts=1, name="JNO", dir=data_path, verbose=false, kw...)
    ts = !ismissing(ts) ? Second(ts) : ts
    tau = !ismissing(tau) ? Second(tau) : tau
    ds = DataSet(; name, ts, tau, kw...)
    df = load(ds; dir)

    if name == "JNO"
        "radial_distance" in names(df) && rename!(df, :radial_distance => :r)
        df.T = df.T .* u"K"
    elseif name == "Wind"
        Discontinuity.calc_T!(df, "T")
    end

    df = df |> post_process!
    verbose && println("Number of events: ", size(df, 1))
    insertcols!(df, :tau => tau, :ts => ts)
end

load_tau(tau) = Discontinuity.load(; tau=tau, verbose=true)

"""the MVAB method can achieve acceptable accuracy when either |B|/|B| > 0.05 or ω > 60°. @liuFailuresMinimumVariance2023"""
assign_accuracy!(df) = @transform!(df, :accuracy = (:ω .> 60) .| (:db_over_b .> 0.05))
filter_low_accuracy(df) = filter(:accuracy => ==(true), df)

"""
# Notes

This will remove events that appear in multiple taus datasets. 
However, this may not remove all "duplicates" that may have little duration differences, since "t_us", :"t_ds" are determined by the maximum distance, and they may vary across different taus for one "event".
"""
function load_taus(; taus=DEFAULT_TAUS, unique_f=["t_us", "t_ds"])
    df = vcat(load_tau.(taus)...)
    ismissing(unique_f) || unique!(df, unique_f)
    df.tau = categorical(df.tau)
    return sort(df, :tau)
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