using DrWatson
@quickactivate

using Discontinuity
using AlgebraOfGraphics,
    CairoMakie
using DataFrames,
    DataFramesMeta,
    CategoricalArrays

using Statistics
using LinearAlgebra
using beforerr
import beforerr: easy_save
using LaTeXStrings

set_aog_theme!()

include("io.jl")
include("plot.jl")

figure_dir = projectdir("figures")
easy_save(fname) = beforerr.easy_save(fname; dir=figure_dir)


