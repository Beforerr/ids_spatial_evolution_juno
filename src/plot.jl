using AlgebraOfGraphics: density

using Dates

nonnumeric_r(x::Number) = string(round(Integer, x))
nonnumeric_r(x) = x

# %%
# Define the labels for the plots
r_lab = L"Radial Distance ($AU$)"
r_map = :r => nonnumeric_r => r_lab
tau_map = :tau => nonnumeric => "τ (s)"
year_map = :time => nonnumeric ∘ year => "Year"
month_map = :time => nonnumeric ∘ month => "Month"
week_map = :time => nonnumeric ∘ week => "Week";

function plot_duration(plt;
    datalimits_f=x -> quantile(x, [0.02, 0.98]),
    axis=(; yscale=log10),
    facet=(; linkxaxes=:none, linkyaxes=:none),
    legend=(; position=:top, titleposition=:left)
)
    plt *= mapping(:duration) * (visual(Lines))
    specs = plt * density(; datalimits=datalimits_f)
    draw(specs, axis=axis, facet=facet, legend=legend)
end