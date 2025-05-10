module THEMIS
using ..Juno: get_time_range, sort_data
using Dates: DateTime, Second
using DrWatson: produce_or_load, dict_list, @unpack
using Speasy: SpeasyProduct, init_cdaweb
using Discontinuity: ids_finder

__init__() = init_cdaweb()

B_GSE = SpeasyProduct("THB_L2_FGM/thb_fgs_gseQ")
B_FGL_GSE = SpeasyProduct("THB_L2_FGM/thb_fgl_gseQ")

SSE_STATE = SpeasyProduct("THB_L2_MERGED/XYZ_SSE")
# THB_L1_STATE/thb_pos_sse

function produce(d)
    START_TIME = DateTime(2011, 9, 9) # There is an np.datetime64('NaT') which makes `Speasy` conversion fail
    @unpack year, period = d
    data = B_FGL_GSE(get_time_range(year, START_TIME)...)
    d["ds"] = ids_finder(sort_data(data), Second(period))
    return d
end

function produce()
    allparams = Dict(
        "id" => ["THB"],
        "period" => [60],
        "year" => collect(2011:2016),
    )
    dicts = produce_or_load.(produce, dict_list(allparams), "data")
    ds = mapreduce(vcat, dicts) do d
        d[1]["ds"]
    end
    return ds
end
end