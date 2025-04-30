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
import Base.round

export subset_by_quantiles
export load_taus

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