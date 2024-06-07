using AlgebraOfGraphics: density

using Dates

round_c(x) = round(Integer, x)

# %%
# Define the labels for the plots
r_lab = L"Radial Distance ($AU$)"
r_map = :radial_distance => nonnumeric ∘ round_c  => r_lab
tau_map = :tau => nonnumeric => "τ (s)"
year_map = :time => nonnumeric ∘ year  => "Year"

function plot_duration(plt; 
    datalimits_f = x -> quantile(x, [0.02, 0.98]),
    axis = (; yscale=log10),
    facet = (; linkxaxes=:none, linkyaxes=:none),
    legend = (; position=:top, titleposition=:left)
)
    plt *= mapping(:duration) * (visual(Lines))
    specs = plt * density(; datalimits=datalimits_f) 
    draw(specs, axis=axis, facet=facet, legend=legend)
end