using Printf
using Arrow

data_path = "$(@__DIR__)/../../data/05_reporting"

function load(path::String)
    df = path |> Arrow.Table |> DataFrame |> dropmissing
    
    # if 'radial_distance' is in the dataframe, round it
    if "radial_distance" in names(df)
        df = @chain df begin
            @transform :r = string.(round.(Int, :radial_distance))
        end
    end

    df = @chain df begin
        @transform(
            :j0_k = abs.(:j0_k),
            :j0_k_norm = abs.(:j0_k_norm),
        )
        
    end

    # Iterate through each column in the DataFrame
    filter(row -> all(x -> !(x isa Number && isnan(x)), row), df)
end

function load(;tau = 60, ts = 1.00, name = "JNO", method = "fit", dir = data_path)
    ts_str = @sprintf "ts_%.2fs" ts
    df = load(joinpath(dir, "events.$name.$method.$(ts_str)_tau_$(tau)s.arrow"))
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