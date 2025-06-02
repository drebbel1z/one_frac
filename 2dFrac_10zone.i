# Units K,m,Pa,Kg,s
# Cold water injection into one side of the fracture network, and production from the other side
# These are initial fracture properties
# fracture permeability = roughness/12 * (aperature_o)^3 = 12e-3/12*(1e-4)^3 = 1e-15 m^-2
# fracture porosity = aperature ~1e-4m
frac_aperature = 2e-4
frac_roughness = 12e-3

# These should just be pass through, so high permeability, porosity ~1
inj_perm = 1.0e-9 #these are from the fracture volumetric fracture properties
inj_poro = .9
matrix_perm = 1.0e-16
matrix_poro = 2.0e-4

biot_coeff = 0.47

endTime = 302400 #86400 # 1day   # 2592000 # 30 days
initial_dt = 100
dt_max = 10000

injection_temp = 323.15

# mesh_size = 20

# NOTE: water weight used in BCs and peacmeans
# because this is used in BCs, it should be reasonably physically correct,
# otherwise the BCs will be withdrawing or injecting water inappropriately.
# Note also that the 9300 should be the unit_weight in the PeacemanBoreholes
# 9300 = density(T=490K,P=23MPa) * gravity(9.8m/s2)
water_weight = 9300 #9300 = density(T=490K,P=23MPa) * gravity(9.8m/s2)

###########################################################
# Fracture materials
!include fracture_materials_nonlinear.i

# injection rates and postprocessors
!include injection_rates.i

# includding injection & production diracs
!include injection_pressure_diracs.i
!include injection_temperature_diracs.i

# includding injection & production pp
!include injection_pressure_pp.i
!include injection_temperature_pp.i
!include production_pressure_pp.i
!include production_temperature_pp.i

###########################################################
[Mesh]
  # parallel_type=distributed
  [fmg]
   type = FileMeshGenerator
   file = '1frac_Fractures_Local_20m_marked.e'
  []
[]

[GlobalParams]
  PorousFlowDictator = dictator
  gravity = '0 0 -9.81'
[]

[Variables]
  [porepressure]
  []
  [temperature]
    scaling = 1e-6
  []
[]

[AuxVariables]
  [Pdiff]
    initial_condition = 0
  []
  [Tdiff]
    initial_condition = 0
  []
  [density]
    order = CONSTANT
    family = MONOMIAL
  []
  [viscosity]
    order = CONSTANT
    family = MONOMIAL
  []
  [insitu_pp]
  []
  [permeability]
    order = CONSTANT
    family = MONOMIAL
  []
  [porosity]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [Pdiff]
    type = ParsedAux
    use_xyzt = true
    variable = Pdiff
    coupled_variables = 'porepressure'
    expression = 'porepressure-(1.6025e7-${water_weight}*(z-1150))'
    execute_on = TIMESTEP_END
  []
  [Tdiff]
    type = ParsedAux
    use_xyzt = true
    variable = Tdiff
    coupled_variables = 'temperature'
    expression = 'temperature-(426.67-0.0733333*(z-1150))'
    execute_on = TIMESTEP_END
  []
  [density]
    type = MaterialRealAux
    variable = density
    property = PorousFlow_fluid_phase_density_qp0
    execute_on = TIMESTEP_END
  []
  [viscosity]
    type = MaterialRealAux
    variable = viscosity
    property = PorousFlow_viscosity_qp0
    execute_on = TIMESTEP_END
  []
  [porosity]
    type = MaterialRealAux
    variable = porosity
    property = PorousFlow_porosity_qp
    execute_on = TIMESTEP_END
  []
  [permeability]
    type = MaterialRealTensorValueAux
    variable = permeability
    property = PorousFlow_permeability_qp
    execute_on = TIMESTEP_END
  []
[]

[Functions]
  # NOTE: because this is used in BCs, it should be reasonably physically correct,
  # otherwise the BCs will be withdrawing or injecting heat-energy inappropriately
  [insitu_T]
    type = ParsedFunction
    expression = '426.67-0.0733333*(z-1150)'
  []
  [insitu_pp]
    type = ParsedFunction
    expression = '1.6025e7-${water_weight}*(z-1150)'
  []
[]

[ICs]
  [porepressure]
    type = FunctionIC
    variable = porepressure
    function = insitu_pp
  []
  [temperature]
    type = FunctionIC
    variable = temperature
    function = insitu_T
  []
  [insitu_pp]
    type = FunctionIC
    variable = insitu_pp
    function = insitu_pp
  []
[]

[PorousFlowFullySaturated]
  coupling_type = ThermoHydro
  porepressure = porepressure
  temperature = temperature
  fp = tabulated_water #the_simple_fluid
  pressure_unit = Pa
  stabilization = full
  #gravity = '0 0 -9.81'
[]

[FluidProperties]
  # [the_simple_fluid]
  #   type = SimpleFluidProperties
  #   bulk_modulus = 2E9
  #   viscosity = 1.0E-3
  #   density0 = 1000.0
  # []
  # [true_water]
  #   type = Water97FluidProperties
  # []
  [tabulated_water]
    type = TabulatedBicubicFluidProperties
    # fp = true_water
    fluid_property_file = ext_fluid_properties2.csv
    # Bounds of interpolation
    # temperature_min = 280
    # temperature_max = 600
  []
[]

[Materials]
  [biot_modulus]
    type = PorousFlowConstantBiotModulus
    biot_coefficient = ${biot_coeff}
    solid_bulk_compliance = 2e-7
    fluid_bulk_modulus = 1e7
  []

  # [porosity_fracture]
  #   type = PorousFlowPorosityConst
  #   porosity = ${frac_poro}
  #   block = ${all_frac_ids}
  # []
  # [permeability_fracture]
  #   type = PorousFlowPermeabilityConst
  #   block = ${all_frac_ids}
  #   permeability = '${frac_perm} 0 0 0 ${frac_perm} 0 0 0 ${frac_perm}'
  # []
  # [rock_internal_energy_fracture]
  #   type = PorousFlowMatrixInternalEnergy
  #   density = 2500.0
  #   specific_heat_capacity = 100.0 # NOTE: Lynn value of 10.0 seemed quite low, so i increased it.  This may not impact the simulation much
  #   block = ${all_frac_ids}
  # []
  # [thermal_conductivity_fracture]
  #   type = PorousFlowThermalConductivityIdeal
  #   dry_thermal_conductivity = '3 0 0 0 3 0 0 0 3'
  #   block = ${all_frac_ids}
  # []
  # blocks 2000, 3000 are production volume elemnts
  [porosity_inj_prod_volume]
    type = PorousFlowPorosityConst
    porosity = ${inj_poro}
    block = '2000 3000'
  []
  [permeability_inj_prod_volume]
    type = PorousFlowPermeabilityConst
    block = '2000 3000'
    permeability = '${inj_perm} 0 0 0 ${inj_perm} 0 0 0 ${inj_perm}'
  []
  [rock_internal_energy_inj_prod_volume]
    type = PorousFlowMatrixInternalEnergy
    density = 2500.0
    specific_heat_capacity = 100.0 
    block = '2000 3000'
  []
  [thermal_conductivity_inj_prod_volume]
    type = PorousFlowThermalConductivityIdeal
    dry_thermal_conductivity = '3 0 0 0 3 0 0 0 3'
    block = '2000 3000'
  []


  [porosity_matrix]
    type = PorousFlowPorosity
    porosity_zero = ${matrix_poro}
    block = '1000'
  []
  # [porosity_matrix]
  #   type = PorousFlowPorosity
  #   porosity_zero = ${matrix_poro}
  #   fluid = true
  #   solid_bulk = 5.4e10
  #   block = '1000'
  # []
  [permeability_matrix]
    type = PorousFlowPermeabilityConst
    permeability = '${matrix_perm} 0 0  0 ${matrix_perm} 0  0 0 ${matrix_perm}'
    block = '1000'
  []
  [rock_internal_energy_matrix]
    type = PorousFlowMatrixInternalEnergy
    density = 2750.0
    specific_heat_capacity = 790.0
    block = '1000'
  []
  [thermal_conductivity_matrix]
    type = PorousFlowThermalConductivityIdeal
    dry_thermal_conductivity = '3.05 0 0 0 3.05 0 0 0 3.05'
    block = '1000'
  []
[]

##########################################################
# [Functions]
#   [mass_flux_src]
#     type = PiecewiseLinear
#     # in bpm
#     x = '0 ${eqt}  ${fparse eqt+1} ${fparse eqt+1e8}'
#     y = '0      0              10                10'
#     scale_factor = 2.65 #convert barrels/minute to kg/s
#   []
# []

#April 2024 circulation test
# [Functions]
#   [mass_flux_src]
#     type = PiecewiseLinear
#     # in bpm
#     x = '0 ${eqt}  ${fparse eqt+1} ${fparse eqt+999} ${fparse eqt+1000} ${fparse eqt+1680} ${fparse eqt+1681} ${fparse eqt+3000} ${fparse eqt+3001} ${fparse eqt+12420} ${fparse eqt+12421} ${fparse eqt+16560} ${fparse eqt+16561} ${fparse eqt+17700} ${fparse eqt+17701} ${fparse eqt+31621} ${fparse eqt+32200} ${fparse eqt+32201} ${fparse eqt+40000}'
#     y = '0      0             2.5                2.5                  6                 6                  11                11               15.5                15.5                  13                  13                   0                   0                  13                  13                10.5                10.5                   0'
#     scale_factor = 2.65 #convert barrels/minute to kg/s
#   []
# []

#April 2024 30 day circulation test from Pengju 2025/04/03
[Functions]
  [mass_flux_src]
    type = PiecewiseLinear
    # in bpm
    xy_data = "0 0
               1 2.5
               85000 2.5
               85001 0
               114500 0
               114501 2.5
               143000 2.5
               143001 5
               186000 5
               186001 7.5
               247000 7.5
               247001 10
               2320400 10
               2320401 7.5
               2321000 7.5
               2321001 5
               2321500 5
               2321501 2.5
               2322200 2.5
               2322201 0
               2325219 0
               2325220 2.5
               2325900 2.5
               2325901 0
               2332970 0
               2332971 2.5
               2334220 2.5
               2334221 0
               2345100 0
               2345101 2.5
               2348680 2.5
               2348681 0"
    scale_factor = 2.65 #convert barrels/minute to kg/s
  []
[]
##########################################################
# PEACEMANS
[Functions]
  [insitu_pp_borehole]
    type = ParsedFunction
    symbol_names = 'back_pressure_Pa'
    symbol_values = '3.44738e6' #500psi back-pressure
    expression = '1.6025e7-${water_weight}*(z-1150)+back_pressure_Pa'
  []
  #delaying production for initial heaviside injection
  [character_function]
    type = PiecewiseLinear
    # in bpm
    xy_data = "0 0
    100000 0
    114500 1"
    # type = ParsedFunction
    # expression = 'if(t < 114500, 0, 1)'
  []
[]

[UserObjects]
  [borehole_fluid_outflow_mass]
    type = PorousFlowSumQuantity
  []
  [borehole_prod_temperature]
    type = PorousFlowSumQuantity
  []
[]

[DiracKernels]
  [withdraw_fluid]
    type = PorousFlowPeacemanBorehole
    variable = porepressure
    bottom_p_or_t = insitu_pp_borehole
    SumQuantityUO = borehole_fluid_outflow_mass
    point_file = peaceman_production_points.txt
    function_of = pressure
    fluid_phase = 0
    unit_weight = '0 0 -${water_weight}'
    use_mobility = true
    character = character_function
    point_not_found_behavior = WARNING
  []
  [bh_energy_flow]
    type = PorousFlowPeacemanBorehole
    variable = temperature
    bottom_p_or_t = insitu_pp_borehole
    SumQuantityUO = borehole_prod_temperature
    point_file = peaceman_production_points.txt
    function_of = pressure
    fluid_phase = 0
    unit_weight = '0 0 -${water_weight}'
    use_mobility = true
    use_enthalpy = true
    character = character_function
    point_not_found_behavior = WARNING
  []
[]

[Postprocessors]
  [fluid_report]
    type = PorousFlowPlotQuantity
    uo = borehole_fluid_outflow_mass
  []
  [energy_prod]
    type = PorousFlowPlotQuantity
    uo = borehole_prod_temperature
  []
[]
##########################################################

[Postprocessors]
  [inject_T]
    type = Receiver
    default = ${injection_temp}
  []
  [param_frac_aperature]
    type = Receiver
    default = '${frac_aperature}'
  []
  [param_frac_roughness]
    type = Receiver
    default = ${frac_roughness}
  []
  [param_matrix_perm]
    type = Receiver
    default = ${matrix_perm}
  []
  [param_matrix_poro]
    type = Receiver
    default = ${matrix_poro}
  []
  [param_biot_coeff]
    type = Receiver
    default = ${biot_coeff}
  []
  [injection_rate_kg_s]
    type = FunctionValuePostprocessor
    function = mass_flux_src
    execute_on = timestep_end
  []
  [a1_dt]
    type = TimestepSize
  []
  [a0_wall_time]
    type = PerfGraphData
    section_name = "Root"
    data_type = total
  []
  [p_well_58_bottom]
    type = PointValue
    variable = Pdiff
    point = '38.51767602 53.58355641 540.3684522'
  []
  [t_well_58_bottom]
    type = PointValue
    variable = Tdiff
    point = '38.51767602 53.58355641 540.3684522'
  []
[]

###########################################################
[Preconditioning]
  active = asm_ilu
  [hypre]
    type = SMP
    full = true
    #petsc_options_iname = '-pc_type -pc_hypre_type -pc_hypre_boomeramg_strong_threshold -pc_hypre_boomeramg_agg_nl -pc_hypre_boomeramg_agg_num_paths -pc_hypre_boomeramg_max_levels -pc_hypre_boomeramg_coarsen_type -pc_hypre_boomeramg_interp_type -pc_hypre_boomeramg_truncfactor'
    #petsc_options_value = 'hypre    boomeramg       0.7                                  4                          5                                 25                             HMIS                             ext+i                           0.3'
    petsc_options = '-ksp_diagonal_scale -ksp_diagonal_scale_fix'
    petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart -pc_hypre_boomeramg_strong_threshold'
    petsc_options_value = 'hypre    boomeramg      31                 0.7'
  []
  [asm_ilu] #uses less memory
    type = SMP
    full = true
    petsc_options = '-ksp_diagonal_scale -ksp_diagonal_scale_fix'
    petsc_options_iname = '-ksp_type -ksp_grmres_restart -pc_type -sub_pc_type -sub_pc_factor_shift_type -pc_asm_overlap'
    petsc_options_value = 'gmres 30 asm ilu NONZERO 2'
  []
  [asm_lu] #uses less memory
    type = SMP
    full = true
    petsc_options = '-ksp_diagonal_scale -ksp_diagonal_scale_fix'
    petsc_options_iname = '-ksp_type -ksp_grmres_restart -pc_type -sub_pc_type -sub_pc_factor_shift_type -pc_asm_overlap'
    petsc_options_value = 'gmres 30 asm lu NONZERO 2'
  []
  [superlu]
    type = SMP
    full = true
    petsc_options = '-ksp_diagonal_scale -ksp_diagonal_scale_fix'
    petsc_options_iname = '-ksp_type -pc_type -pc_factor_mat_solver_package'
    petsc_options_value = 'gmres lu superlu_dist'
  []
  [preferred]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
    petsc_options_value = ' lu       mumps'
  []
[]
[Executioner]
  type = Transient
  solve_type = NEWTON
  end_time = ${endTime}
  dtmin = 0.5
  dtmax = ${dt_max}
  l_tol = 1e-4
  l_max_its = 500
  nl_max_its = 20
  nl_abs_tol = 1e-6
  nl_rel_tol = 1e-5 #rkp
  error_on_dtmin = false
  automatic_scaling = true
  start_time = -1000
  # compute_scaling_once = false

  line_search = none
  #predictor helps but the nl_rel_tol is hard to satisfy.
  # [Predictor]
  #   type = SimplePredictor
  #   scale = 1.0
  # []
  [TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 10
    iteration_window = 5
    growth_factor = 1.2
    cutback_factor = 0.9
    cutback_factor_at_failure = 0.5
    linear_iteration_ratio = 1000
    dt = ${initial_dt}
    force_step_every_function_point = true
    post_function_sync_dt = 100
    timestep_limiting_function = mass_flux_src
  []
[]

##############################################################
[Outputs]
  console=false
#   file_base = 'outputs/results_nlmat_${mesh_size}m_orig'
#   csv = true
#   print_linear_residuals = false
#   wall_time_checkpoint = false
#  [exo]
#   #  time_step_interval = 5
#    type = Exodus
#  []
  # [nem]
  #   time_step_interval = 5
  #   type = Nemesis
  #   hide = 'porepressure temperature insitu_pp viscosity density'
  # []
  # [nem]
  #   file_base = 'outputs/result'
  #   type = Nemesis
  #   time_step_interval = 2
  #   # hide = 'hmin cut porepressure temperature'
  #   # sync_times = '1 2 3 4 5
  #   # 100 200 300 400 500 600 700 800 900
  #   # 1e3 2e3 3e3 4e3 5e3 6e3 7e3 8e3 9e3
  #   # 1e4 2e4 3e4 4e4 5e4 6e4 7e4
  #   # 86400 172800 259200 345600 432000 518400 604800 691200 777600 864000
  #   # 950400 1036800 1123200 1209600 1296000 1382400 1468800 1555200 1641600 1728000
  #   # 1814400 1900800 1987200 2073600 2160000 2246400 2332800 2419200 2505600 2592000'
  #   # sync_only = true
  # []
[]
