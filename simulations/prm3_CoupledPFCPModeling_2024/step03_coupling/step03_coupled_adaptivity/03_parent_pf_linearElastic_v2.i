
my_filename = "main_pf_linear"

[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 40
  ny = 40
  xmax = 1000
  ymax = 1000
  elem_type = QUAD4

  parallel_type = distributed
[]

[GlobalParams]
  op_num = 2
  var_name_base = gr

  time_scale = 1.0e-6
[]

[Variables]
  [./PolycrystalVariables]
  [../]
[]

[Adaptivity]
  marker = marker
  max_h_level = 4
  [./Indicators]
    [./error]
      type = GradientJumpIndicator
      variable = bnds
    [../]
  [../]
  [./Markers]
    [./marker]
      type = ErrorFractionMarker
      coarsen = 0.1
      indicator = error
      refine = 0.7
    [../]
  [../]
[]

[UserObjects]
  [./grain_tracker]
    type = GrainTracker
    compute_var_to_feature_map = true
    flood_entity_type = elemental
    execute_on = 'initial timestep_begin'
    outputs = none
  [../]
[]

[ICs]
  [./PolycrystalICs]
    [./BicrystalBoundingBoxIC]
      x1 = 0
      y1 = 0
      x2 = 500
      y2 = 1000
    [../]
  [../]
[]

[AuxVariables]
  [./bnds]
    order = FIRST
    family = LAGRANGE
  [../]
  [./gr0_grainId]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./gr1_grainId]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./grain_ids]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./var_ids]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[Kernels]
  [./PolycrystalKernel]
  [../]
[]

[AuxKernels]
  [./bnds_aux]
    type = BndsCalcAux
    variable = bnds
    execute_on = timestep_end
  [../]
  [./grain_ids]
    type = FeatureFloodCountAux
    variable = grain_ids
    flood_counter = grain_tracker
    execute_on = 'initial timestep_begin'
    field_display = UNIQUE_REGION
  [../]
  [./var_ids]
    type = FeatureFloodCountAux
    variable = var_ids
    flood_counter = grain_tracker
    execute_on = 'initial timestep_begin'
    field_display = VARIABLE_COLORING
  [../]
[]

[Materials]
  [./Copper]
    type = GBEvolution
    block = 0
    T = 500 # K
    wGB = 75 # nm
    GBmob0 = 2.5e-6 # m^4/(Js) from Schoenfelder 1997
    Q = 0.23 # Migration energy in eV
    GBenergy = 0.708 # GB energy in J/m^2
  [../]
[]

[Postprocessors]
  [./dt]
    type = TimestepSize
  [../]
  [./gr0_area]
    type = ElementIntegralVariablePostprocessor
    variable = gr0
  [../]
[]

[Preconditioning]
  [./SMP]
   type = SMP
   coupled_groups = 'gr0, gr1'
  [../]
[]

[Executioner]
  type = Transient

  solve_type = 'PJFNK'
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart -pc_hypre_boomeramg_strong_threshold'
  petsc_options_value = 'hypre boomeramg 31 0.7'

  l_max_its = 30
  l_tol = 1e-4

  nl_max_its = 30
  nl_abs_tol = 1e-10
  nl_rel_tol = 1e-9
  nl_rel_step_tol = 1e-10
  nl_abs_step_tol = 1e-10

  fixed_point_max_its = 20 # Specifies the maximum number of fixed point iterations.
  accept_on_max_fixed_point_iteration = true
  fixed_point_rel_tol = 1e-8
  fixed_point_abs_tol = 1e-10

  start_time = 0.0
  num_steps = 3
  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 0.05
    growth_factor = 1.2
    cutback_factor = 0.8
    optimal_iterations = 8
  [../]
[]

[Outputs]
  execute_on = 'timestep_end'
  [my_exodus]
    type = Nemesis
    file_base = ./${my_filename}/out_${my_filename}
    # interval
  [../]
  print_linear_residuals = false
[]

[MultiApps]
  [./sub_cp]
    type = TransientMultiApp
    clone_parent_mesh = false
    positions = '0 0 0'
    input_files = '03_sub_cp_linearElastic_v2.i'
    sub_cycling = true
    execute_on = 'timestep_end'

    # output_in_position = true
  [../]
[]

[Transfers]
  [./marker_to_sub]
    type = LevelSetMeshRefinementTransfer
    to_multi_app = sub_cp
    source_variable = marker
    variable = marker
    check_multiapp_execute_on = false
    # execute_on = 'timestep_begin'
  [../]
  [./push_gr0]
    type = MultiAppGeneralFieldNearestLocationTransfer # MultiAppCopyTransfer
    to_multi_app = sub_cp
    source_variable = gr0
    variable = gr0
  [../]
  [./push_gr1]
    type = MultiAppGeneralFieldNearestLocationTransfer
    to_multi_app = sub_cp
    source_variable = gr1
    variable = gr1
  [../]
[]