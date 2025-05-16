using Speasy: init_cdaweb, init_archive
using DataToolkit

init_provider() = (init_cdaweb(); init_archive(); loadcollection!("Data.toml"))

function general_produce(d::Dict; split=Day(30), kw...)
    @unpack year, period, B = d
    timerange = get_time_range(year)
    d["ds"] = ids_finder(B, timerange..., Second(period); split, kw...)
    return d
end

function general_produce(id, B; f=general_produce, kw...)
    allparams = Dict(
        "id" => id,
        "period" => [60],
        "year" => collect(2011:2016),
        "B" => B,
    )
    dicts = produce_or_load.(f, dict_list(allparams), "data")
    ds = mapreduce(vcat, dicts) do d
        d[1]["ds"]
    end
    ds.id .= id
    return ds
end

module THEMIS
using Speasy: SpeasyProduct, getdimarray
using SPEDAS: tsort
using DataToolkit, DataFramesMeta
using SpaceDataModel: parse_doy_datetime

const B_GSE = SpeasyProduct("THB_L2_FGM/thb_fgs_gseQ")
const B_FGL_GSE = (args...; kw...) -> tsort(getdimarray("archive/local/THB_L2_FGM/thb_fgl_gse", args...; sanitize=true, kw...))
const B_FGS_GSE = (args...; kw...) -> tsort(getdimarray("archive/local/THB_L2_FGM/thb_fgs_gse", args...; sanitize=true, kw...))

const SSE_STATE = SpeasyProduct("THB_L2_MERGED/XYZ_SSE")
# THB_L1_STATE/thb_pos_sse

themis_b_sw() = @select!(
    d"themis_b_sw",
    :start = parse_doy_datetime.(:start),
    :stop = parse_doy_datetime.(:end)
)
end

module Wind
using Speasy: SpeasyProduct
const B_RTN = SpeasyProduct("archive/local/WI_H4-RTN_MFI/BRTN")
end

module STEREO
using Speasy: SpeasyProduct
using SPEDAS: tsort
preprocess(da) = @views tsort(da[:, 1:3])
preprocess(::Nothing) = nothing
const B_RTN = SpeasyProduct("archive/local/STA_L1_MAG_RTN/BFIELD")
B_RTN3 = preprocess ∘ B_RTN
end