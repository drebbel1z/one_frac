# created by write_frac_materials_input.py
# see Materials Property section in porous flow notes: 
# https://mooseframework.inl.gov/modules/porous_flow/multiapp_fracture_flow_PorousFlow_3D.html 
# DFN from fname 
all_frac_ids = "fracture1 "

frac_aperture_1 = ${frac_aperature}

frac_roughness_1 = ${frac_roughness}

one_over_bulk = 1.4e-11 #bulk modulus = 70GPa

[Materials]
  [porosity_fracture1]
    type = PorousFlowPorosityLinear
    porosity_ref = ${frac_aperture_1}
    P_ref = insitu_pp
    P_coeff = ${one_over_bulk}
    porosity_min = ${fparse frac_aperture_1/10}
    block = fracture1
  []
  [permeability_fracture1]
    type = PorousFlowPermeabilityKozenyCarman
    k0 = ${fparse frac_roughness_1/12*frac_aperture_1^3}
    poroperm_function = kozeny_carman_phi0
    m = 0
    n = 3
    phi0 = ${frac_aperture_1}
    block = fracture1
  []

  [rock_internal_energy_fracture]
    type = PorousFlowMatrixInternalEnergy
    density = 2500
    specific_heat_capacity = 100.0
    block = ${all_frac_ids}
  []

  [thermal_conductivity_fracture]
    type = PorousFlowThermalConductivityIdeal
    dry_thermal_conductivity = '3 0 0 0 3 0 0 0 3'
    block = ${all_frac_ids}
  []
[]
