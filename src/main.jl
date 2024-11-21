using DrWatson
@quickactivate

using AlgebraOfGraphics,
    CairoMakie
using DataFrames,
    DataFramesMeta,
    CategoricalArrays

using Statistics
using LinearAlgebra
using Beforerr
import Beforerr: easy_save
using LaTeXStrings
using Discontinuity
using Unitful
import Base.round

set_aog_theme!()
theme = Theme(; colormap=Reverse(:tokyo), figure_padding=2)
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

dfplot(layer, args...; axis=(;), kwargs...) = draw(layer * mapping(args...; kwargs...); axis)
dfplot(df::AbstractDataFrame, args...; axis=(;), kwargs...) = draw(data(df) * mapping(args...; kwargs...); axis)