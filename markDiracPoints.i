case_name="1frac"
mesh_size="20"
[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = '1frac_rm_duplicate.e'
  []
  add_subdomain_ids = '2000 3000' #2000=injection subdomain; 3000=production subdomain
[]

[Problem]
  solve = False
[]

[VectorPostprocessors]
  [injection_points]
    type = CSVReaderVectorPostprocessor
    csv_file = "../simulation_inputs/injection_points.csv"
  []
  [production_points]
    type = CSVReaderVectorPostprocessor
    csv_file = "../simulation_inputs/production_points.csv"
  []
[]

[Adaptivity]
  [Markers]
    [injection]
      type = ReporterPointMarker
      x_coord_name = injection_points/x
      y_coord_name = injection_points/y
      z_coord_name = injection_points/z
      inside = refine
      empty = do_nothing
    []
    [production]
      type = ReporterPointMarker
      x_coord_name = production_points/x
      y_coord_name = production_points/y
      z_coord_name = production_points/z
      inside = refine
      empty = do_nothing
    []
  []
[]

[UserObjects]
  [injection_subdomain]
    type = CoupledVarThresholdElementSubdomainModifier
    coupled_var = 'injection'
    criterion_type = ABOVE
    threshold = 1.1
    subdomain_id = 2000
    complement_subdomain_id = 1000
    block = 1000
  []
  [production_subdomain]
    type = CoupledVarThresholdElementSubdomainModifier
    coupled_var = 'production'
    criterion_type = ABOVE
    threshold = 1.1
    subdomain_id = 3000
    complement_subdomain_id = 1000
    block = 1000
  []
[]

[Executioner]
  type = Transient #Steady
  solve_type = LINEAR
  num_steps = 3
[]

[Outputs]
  file_base=${case_name}_Fractures_Local_${mesh_size}m_marked
  exodus = true
  execute_on = FINAL
[]
