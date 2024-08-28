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

set_aog_theme!()

include("io.jl")
include("plot.jl")

figure_dir = projectdir("figures")
easy_save(fname) = beforerr.easy_save(fname; dir=figure_dir)

datalimits_f = x -> quantile(x, [0.02, 0.98])

