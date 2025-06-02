# created by write_diracs_input.py
[DiracKernels]
  [source_1_h]
    type = PorousFlowPointEnthalpySourceFromPostprocessor
    variable = temperature
    mass_flux = mass_flux_src_stage_1
    point = '4.1345165890 220.1299407155 396.4301458718'
    T_in = inject_T
    pressure = porepressure
    fp = tabulated_water
    point_not_found_behavior = WARNING
    # block = 100
  []
[]
