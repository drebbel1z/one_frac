# created by write_frac_materials_input.py
# DFN from fname 
all_frac_ids = "fracture1 "

poro_fracture1 = ${frac_poro}

perm_fracture1 = ${frac_perm}


[Materials]
  [porosity_fracture1]
    type = PorousFlowPorosityConst
    porosity = ${poro_fracture1}
    block = fracture1
  []
  [permeability_fracture1]
    type = PorousFlowPermeabilityConst
    permeability = '${perm_fracture1} 0 0 0 ${perm_fracture1} 0 0 0 ${perm_fracture1}'
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
