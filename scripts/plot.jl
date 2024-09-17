using DrWatson
@quickactivate
include("../src/main.jl")
import Base.copy

Base.copy(x::Figure) = x
safe_produce(f, c; kwargs...) = produce_or_load(f, c, figure_dir; filename=hash, suffix="svg", loadfile=false, kwargs...)

function plot_dist_r(config)
    @unpack df = config
    return plot_dist(
        data(df) * mapping(color=r_map);
        datalimits=datalimits_f,
    )
end

function main()
    # j_events_taus = load_taus(60:-10:20)
    jno_df = load(datadir("updated_events_JNO_tr=20110825-20160630_method=fit_tau=0:01:00_ts=0:00:01.arrow"))
    config = @dict df = jno_df
    safe_produce(plot_dist_r, config; prefix="juno_distribution_r")
end

main()