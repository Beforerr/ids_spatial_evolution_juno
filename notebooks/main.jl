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
using PartialFunctions

set_aog_theme!()

include("utils/io.jl")
# include("utils/Discontinuity.jl")
include("../../share/src/Discontinuity.jl/Discontinuity.jl")

easy_save(fname) = beforerr.easy_save(fname; dir="../figures")

# %%
# Define the labels for the plots
r_lab = L"Radial Distance ($AU$)"
