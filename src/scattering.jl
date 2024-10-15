using PlasmaFormulary: ion_gyrofrequency
using DataFramesMeta

# velocity v is normalized to $v0 = l Ω$, where $l$ represents the width of the RD and $Ω = q B/(mpc)$ is the cyclotron frequency.
function v_norm!(df::AbstractDataFrame)
    # gyrofrequency
    @chain df begin
        @transform!(
            :Ω = ion_gyrofrequency.(:"B.mean"),
            :θ = acosd.(:bn_over_b)
        )
        @transform!(:v0 = :L_k .* :Ω)
    end
end

θ = :θ => "azimuthal angle"
Bn = :bn_over_b => abs => L"B_N/B";
v0 = :v0 => log10 => "Log v0";