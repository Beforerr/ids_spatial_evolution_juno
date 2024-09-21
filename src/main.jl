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
using Discontinuity.DefaultMapping
using Unitful

set_aog_theme!()

include("io.jl")
include("plot.jl")

figure_dir = projectdir("figures")
easy_save(fname, fig) = Beforerr.easy_save(fname, fig; formats=[:svg], dir=figure_dir)

datalimits_f = x -> quantile(x, [0.02, 0.98])

import Base.log10
log10(x::Unitful.Quantity) = log10(ustrip(x))