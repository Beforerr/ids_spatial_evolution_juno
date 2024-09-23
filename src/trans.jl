using LinearAlgebra

function rotation_angle(u, v)
    cos_theta = dot(u, v) / (norm(u) * norm(v))
    theta = acos(cos_theta)
    return rad2deg(theta)
end

"""
# Notes
- en_cols = [:Vn_x, :Vn_y, :Vn_z] # unit vector of the normal from MVA
- ek_cols = [:k_x, :k_y, :k_z] # unit vector of the normal from cross product
- v_cols = [:v_x, :v_y, :v_z] # vector of the velocity
"""
function calc_rotation_angle!(df)
    @rtransform!(
        df,
        :θ_vn = rotation_angle([:v_x, :v_y, :v_z], [:Vn_x, :Vn_y, :Vn_z]),
        :θ_vk = rotation_angle([:v_x, :v_y, :v_z], [:k_x, :k_y, :k_z]),
        :θ_nk = rotation_angle([:Vn_x, :Vn_y, :Vn_z], [:k_x, :k_y, :k_z]),
    )
end