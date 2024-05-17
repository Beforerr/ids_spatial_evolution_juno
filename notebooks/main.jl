using AlgebraOfGraphics,
    CairoMakie
using DataFrames,
    DataFramesMeta,
    CategoricalArrays

using Statistics
using LinearAlgebra
using beforerr
using LaTeXStrings
using PartialFunctions

set_aog_theme!()

include("utils/io.jl")
include("utils.jl")
# include("utils/Discontinuity.jl")
include("../../share/src/Discontinuity.jl/Discontinuity.jl")


# %%
# Define the labels for the plots
r_lab = L"Radial Distance ($AU$)"
