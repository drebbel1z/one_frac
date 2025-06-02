####### INJECTION PRESSURE POSTPROCESSORS
# created by write_diracs_input.py
[Postprocessors]
  [p_in_1]
    type = PointValue
    variable = Pdiff
    point = '4.134516589 220.1299407155 396.4301458718'
  []

  [int_pdiff]
    type = TimeIntegratedPostprocessor
    value = p_in_1
    execute_on = 'final'
  []

  [log_inverse_error]
    type = FunctionValuePostprocessor
    function = 'log_inv_error'
  []  
[]

[Functions]
  [log_inv_error]
    type = ParsedFunction
    expression = 'log(1/((a-366132783.32999784)^2))'
    symbol_names = 'a'
    symbol_values = 'int_pdiff'
  []
[]


