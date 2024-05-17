using Printf
using Dates

data_path = "$(@__DIR__)/../../data/05_reporting"

function load(;tau = 60, ts = 1.00, name = "JNO", method = "fit", dir = data_path)
    ts_str = @sprintf "ts_%.2fs" ts
    df = DiscontinuityIO.load(joinpath(dir, "events.$name.$method.$(ts_str)_tau_$(tau)s.arrow"))
    df.tau .= tau
    df.ts .= ts
    
    if method == "fit"
        df = @chain df begin
            filter(:"fit.stat.rsquared" => >(0.95), _)
        end
    end
    df
end


function load_tau(tau)
    df = load(tau=tau)
    df.label .= "$tau s"
    println("Number of events: ", size(df, 1))
    df
end

function process(df)
    df_tmp = @transform(df,
        :year = year.(:time) |> categorical   
    )

    # if 'radial_distance' is in the dataframe, round it
    if "radial_distance" in names(df_tmp)
        @transform!(df_tmp, :r = string.(round.(Int, :radial_distance)))
    end

    return df_tmp
end


function test_load()
    j_events_low_fit = load()
    j_events_tau_20_fit = load(tau = 20)
    j_events_high_fit = load(ts = 0.12)

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

    j_events_taus = 60:-10:20 .|> load_tau |> x -> reduce(vcat, x);

    println("Number of events: ", size(j_events, 1))

    j_events_low_der = load(method="derivative")
    j_events_high_der = load(ts = 0.12, method="derivative")
    
    j_events_low_der[!, :label] .= "1 Hz (derivative)"
    j_events_high_der[!, :label] .= "8 Hz (derivative)"
    j_events_der = vcat(j_events_low_der, j_events_high_der, cols=:intersect)
end