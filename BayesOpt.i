[StochasticTools]
[]

[Distributions]
  [fracture_aperture]
    type = Uniform
    lower_bound = 1e-5
    upper_bound = 4e-4
  []
  [fracture_roughness]
    type = Uniform
    lower_bound =  5e-3 
    upper_bound =  20e-3
  []
[]

[ParallelAcquisition]
  [expectedimprovement]
    type = ExpectedImprovement
    tuning = 1.0
    # require_full_covariance = true
  []
[]

[Samplers]
  [sample]
    type = GenericActiveLearningSampler
    distributions = 'fracture_aperture fracture_roughness'
    sorted_indices = 'conditional/sorted_indices'
    num_parallel_proposals = 5
    num_tries = 3000
    seed = 100
    execute_on = PRE_MULTIAPP_SETUP
    initial_values = "2e-4 12e-3"
  []
[]

[MultiApps]
  [sub]
    type = SamplerFullSolveMultiApp
    input_files = 2dFrac_10zone.i
    sampler = sample
  []
[]

[Transfers]
  [reporter_transfer]
    type = SamplerReporterTransfer
    from_reporter = 'log_inverse_error/value'
    stochastic_reporter = 'constant'
    from_multi_app = sub
    sampler = sample
  []
[]

[Controls]
  [cmdline]
    type = MultiAppSamplerControl
    multi_app = sub
    sampler = sample
    param_names = 'frac_aperature frac_roughness'
  []
[]

[Reporters]
  [constant]
    type = StochasticReporter
  []
  [conditional]
    type = GenericActiveLearner
    output_value = constant/reporter_transfer:log_inverse_error:value
    sampler = sample
    al_gp = GP_al_trainer
    gp_evaluator = GP_eval
    acquisition = 'expectedimprovement'
    penalize_acquisition = true
  []
[]

[Trainers]
  [GP_al_trainer]
    type = ActiveLearningGaussianProcess
    covariance_function = 'covar'
    standardize_params = 'true'
    standardize_data = 'true'
    tune_parameters = 'covar:signal_variance covar:length_factor'
    num_iters = 500
    learning_rate = 0.01
    # show_every_nth_iteration = 100
    batch_size = 350
  []
[]

[Surrogates]
  [GP_eval]
    type = GaussianProcessSurrogate
    trainer = GP_al_trainer
  []
[]

[Covariance]
  [covar]
    type = SquaredExponentialCovariance
    signal_variance = 4.0
    noise_variance = 1e-6
    length_factor = '4.0 4.0'
  []
[]

[Executioner]
  type = Transient
  num_steps = 10
[]

[Outputs]
  file_base = 'al1'
  [out1_parallelAL]
    type = JSON
    execute_system_information_on = NONE
  []
[]
