module Data
using Parquet2
using Arrow
using CSV
using Unitful
using DataFrames, DataFramesMeta
using DimensionalData
using DimensionalData: DimArray, Ti, Y, ForwardOrdered, Unordered
using SpaceDataModel: parse_doy_datetime

export get_mag_data, get_state_data, read_sw_params_csv

data_dir = homedir() * "/data"

_nonmissingtype(::AbstractArray{T}) where {T} = Array{nonmissingtype(T)}
nonmissing(x) = convert(_nonmissingtype(x), x)

load(ds, col) = Parquet2.load(ds, col) |> nonmissing

function get_mag_data(time; dir="data/03_primary/JNO_MAG_ts_1s", cols=["BX SE", "BY SE", "BZ SE"])
    file = "$time.parquet"
    ds = Parquet2.Dataset(dir * "/" * file)
    data = reduce(hcat, load(ds, col) for col in cols)
    times = load(ds, "time")
    t_dim = Ti(times)
    dims = (t_dim, Y())
    return DimArray(data, dims)
end

# '/Volumes/My Passport for Mac/data/02_intermediate/JNO_MAG_8hz/fgm_jno_l3_2016181se_v01.arrow'
function get_mag_data(year, doy; dir=homedir() * "/data/02_intermediate/JNO_MAG_8hz", cols=["BX SE", "BY SE", "BZ SE"])
    file = "fgm_jno_l3_$(year)$(string(doy, pad=3))se_v01.arrow"
    ds = Arrow.Table(dir * "/" * file)
    # data = reduce(hcat, load(ds, col) for col in cols)
    # times = load(ds, "time")
    # t_dim = Ti(times)
    # dims = (t_dim, Y())
    # return DimArray(data, dims)
end

function get_state_data(file="JNO_STATE_ts_3600s.parquet"; dir="./data/03_primary")
    path = dir * "/" * file
    v_cols = ("v_x", "v_y", "v_z")

    ds = Parquet2.Dataset(path)
    times = load(ds, "time")
    t_dim = Ti(times)

    n = DimArray(load(ds, "plasma_density"), (t_dim,))
    v_data = reduce(hcat, load(ds, col) for col in v_cols)
    v = DimArray(v_data, (t_dim, Y()))
    T = DimArray(load(ds, "plasma_temperature"), (t_dim,))
    r = DimArray(load(ds, "radial_distance"), (t_dim,))
    return (; n, v, T, r)
end

"""Reads the solar wind parameters CSV file and returns a DataFrame."""
function read_sw_params_csv(file="./data/jgra54158-sup-0001-supinfo.csv"; add_unit=false)
    df = CSV.read(file, DataFrame)

    @transform! df :time = parse_doy_datetime.(:UTC)

    add_unit && @transform! df begin
        :N_PROTONS_CC = :N_PROTONS_CC * u"cm^-3"
        :V_KMPS = :V_KMPS * u"km/s"
        :T_PROTONS_EV = :T_PROTONS_EV * u"eV"
    end
    df
end

function add_state_info!(df, state=get_state_data())
    selector = Ti(Near(df.time))
    df.r = parent(state.r[selector])
    df.T = parent(state.T[selector]) * u"K"
end

end