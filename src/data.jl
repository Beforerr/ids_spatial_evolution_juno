module Data
using Parquet2
using DimensionalData
using DimensionalData: DimArray, Ti, Y, ForwardOrdered, Unordered

export get_mag_data, get_state_data

data_dir = homedir() * "/data"

_nonmissingtype(::AbstractArray{T}) where {T} = Array{nonmissingtype(T)}
nonmissing(x) = convert(_nonmissingtype(x), x)

load(ds, col) = Parquet2.load(ds, col) |> nonmissing

function get_mag_data(file="2011.parquet"; dir="data/03_primary/JNO_MAG_ts_1s", cols=["BX SE", "BY SE", "BZ SE"])
    ds = Parquet2.Dataset(dir * "/" * file)
    data = reduce(hcat, load(ds, col) for col in cols)
    times = load(ds, "time")
    t_dim = Ti(times)
    dims = (t_dim, Y())
    return DimArray(data, dims)
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


end