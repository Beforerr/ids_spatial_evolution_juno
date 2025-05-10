module Juno
using DrWatson
using AlgebraOfGraphics,
    CairoMakie
using DataFrames,
    DataFramesMeta,
    CategoricalArrays

using NaNStatistics: nanpctile
using Statistics: quantile
using Beforerr
using LaTeXStrings
using Discontinuity
using Unitful
using Dates: DateTime
import Base.round

export subset_by_quantiles
export load_taus

const START_TIME = DateTime(2011, 8, 25)
const END_TIME = DateTime(2016, 6, 30)
const TIME_RANGE = (START_TIME, END_TIME)
const TEST_TIME_RANGE = (DateTime(2012, 1, 1), DateTime(2012, 1, 2))

function get_time_range(yr, start=START_TIME, stop=END_TIME)
    yr == year(start) && return (start, DateTime(yr + 1))
    yr == year(stop) && return (DateTime(yr), stop)
    yr < year(start) || yr > year(stop) && @info "Year $yr is outside the $TIME_RANGE"
    return (DateTime(yr), DateTime(yr + 1))
end

using DimensionalData
using DimensionalData: rebuild, setdims, _astuple
const DD = DimensionalData

function sort_data(A, dim=Ti)
    time = parent(DD.dims(A, dim))
    issorted(time) ? A : begin
        newdata = sortslices(parent(A); dims=dimnum(A, dim))
        newtime = dim(sort(time))
        rebuild(A, newdata, setdims(DD.dims(A), newtime))
    end
end

set_aog_theme!()
theme = Theme(;
    colormap=Reverse(:tokyo),
    figure_padding=2,
    Axis=(
        xminorticksvisible=true,
        yminorticksvisible=true
    )
)
update_theme!(theme)

include("io.jl")
include("plot.jl")
include("data.jl")
include("THEMIS.jl")

datalimits_f = x -> quantile(x, [0.02, 0.98])

foreach([:log10, :log2, :log]) do f
    @eval import Base: $f
    @eval $f(x::Unitful.Quantity) = $f(ustrip(x))
end

# Generalize function to round float like time
Base.round(x::Number, y::Number; kw...) = y * round(x / y; kw...)

struct Bound{T}
    lower::T
    upper::T
end
Bound(nt) = Bound(nt[1], nt[2])
Base.in(x, bound::Bound) = bound.lower ≤ x ≤ bound.upper
Base.in(::Missing, ::Bound) = false

"""
    subset_by_quantiles(df, cols; lower=0.01, upper=0.99)

Returns a subset of `df` containing only rows where, for each column `col` in `cols`,
the values lie between the `lower` and `upper` quantiles of `col`.
"""
function subset_by_quantiles(df, cols; lower=0.01, upper=0.99)
    bounds = map(cols) do col
        Bound(quantile.(Ref(skipmissing(df[!, col])), (lower, upper)))
    end
    f(row) = all(in(row[cols[i]], bounds[i]) for i in eachindex(cols))
    return filter(f, df)
end

dfplot(layer, args...; axis=(;), kwargs...) = draw(layer * mapping(args...; kwargs...); axis)
dfplot(df::AbstractDataFrame, args...; axis=(;), kwargs...) = draw(data(df) * mapping(args...; kwargs...); axis)
end