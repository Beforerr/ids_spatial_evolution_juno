using Printf

function load(path::String)
    df = path |> Arrow.Table |> DataFrame |> dropmissing
    
    # if 'radial_distance' is in the dataframe, round it
    if "radial_distance" in names(df)
        df = @chain df begin
            @transform :r = string.(round.(Int, :radial_distance))
        end
    end

    df = @chain df begin
        @transform(
            :j0_k = abs.(:j0_k),
            :j0_k_norm = abs.(:j0_k_norm),
        )
    end

    # Iterate through each column in the DataFrame
    filter(row -> all(x -> !(x isa Number && isnan(x)), row), df)
end

function load(;tau = 60, ts = 1.00, name = "JNO", method = "fit", dir = "../data/05_reporting")
    ts_str = @sprintf "ts_%.2fs" ts
    df = load(joinpath(dir, "events.$name.$method.$(ts_str)_tau_$(tau)s.arrow"))
    df.tau .= tau
    df.ts .= ts
    df
end

# %%
# Define the labels for the plots
r_lab = L"Radial Distance ($AU$)"
j_lab = L"Current Density ($nA/m^2$)"
l_lab = L"Thickness ($km$)"

l_norm_lab = L"Normalized Thickness ($d_i$)"
j_norm_lab = L"Normalized Current Density ($J_A$)"

di_lab = L"Ion Inertial Length ($km$)"
jA_lab = L"Alfvénic Current Density ($nA/m^2$)"

# %%
# Define the mappings
di_map = :ion_inertial_length => di_lab
di_log_map = :ion_inertial_length => log10 => L"Log %$di_lab"

jA_map = :j_Alfven => jA_lab
jA_log_map = :j_Alfven => log10 => L"Log %$jA_lab"

l_map = :L_k => l_lab
l_norm_map = :L_k_norm => l_norm_lab
l_log_map = :L_k => log10 => L"Log %$l_lab"
l_norm_log_map = :L_k_norm => log10 => L"Log %$l_norm_lab"


current_map = :j0_k => j_lab
current_norm_map = :j0_k_norm => j_norm_lab


j_map = :j0_k => j_lab
j_norm_map = :j0_k_norm => j_norm_lab
j_log_map = :j0_k => log10 => L"Log %$j_lab"
j_norm_log_map = :j0_k_norm => log10 => L"Log %$j_norm_lab"