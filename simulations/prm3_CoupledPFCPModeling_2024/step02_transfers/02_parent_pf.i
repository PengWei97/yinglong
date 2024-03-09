[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 50
  ny = 50
  xmax = 1000
  ymax = 1000
  elem_type = QUAD4

  parallel_type = distributed
[]

[GlobalParams]
  op_num = 2
  var_name_base = gr
[]

[Variables]
  [./PolycrystalVariables]
  [../]
[]

[UserObjects]
  [./euler_angle_file]
    type = EulerAngleFileReader
    file_name = test.tex
  [../]
  # [./grain_tracker]
  #   type = GrainTrackerElasticity
  #   connecting_threshold = 0.05
  #   compute_var_to_feature_map = true
  #   flood_entity_type = ELEMENTAL
  #   execute_on = 'initial timestep_begin'

  #   euler_angle_provider = euler_angle_file
  #   C_ijkl = '1.27e5 0.708e5 0.708e5 1.27e5 0.708e5 1.27e5 0.7355e5 0.7355e5 0.7355e5'
  #   fill_method = symmetric9

  #   outputs = none
  # [../]
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
  [./grain_ids]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./df_elastic_dgr0]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./df_elastic_dgr1]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./var_ids]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./active_bounds_elemental]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./euler_angle_1]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./euler_angle_2]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./euler_angle_3]
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
  [./active_bounds_elemental]
    type = FeatureFloodCountAux
    variable = active_bounds_elemental
    field_display = ACTIVE_BOUNDS
    execute_on = 'initial timestep_begin'
    flood_counter = grain_tracker
  [../]
  [./euler_angle_1]
    type = OutputEulerAngles
    variable = euler_angle_1
    euler_angle_provider = euler_angle_file
    grain_tracker = grain_tracker
    output_euler_angle = 'phi1'
  [../]
  [./euler_angle_2]
    type = OutputEulerAngles
    variable = euler_angle_2
    euler_angle_provider = euler_angle_file
    grain_tracker = grain_tracker
    output_euler_angle = 'Phi'
  [../]
  [./euler_angle_3]
    type = OutputEulerAngles
    variable = euler_angle_3
    euler_angle_provider = euler_angle_file
    grain_tracker = grain_tracker
    output_euler_angle = 'phi2'
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
    time_scale = 1.0e-6
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
  # end_time = 100
  dt = 0.05
  num_steps = 12
[]

[Outputs]
  execute_on = 'timestep_end'
  [my_exodus]
    type = Nemesis
    # sync_times = '0.1 0.5	1	1.5	2	2.5	3	3.5	4	4.5	5	5.5	6	6.5	7	7.5	8	8.5	9	9.5	10	10.5	11	11.5	12	12.5	13	13.5	14	14.5	15	15.5	16	16.5	17	17.5	18 20 30 40 50 60 70 80 90 100'
    # sync_only = true
    interval = 3
  [../]
  print_linear_residuals = false
[]

[MultiApps]
  [./sub_cp]
    type = TransientMultiApp
    clone_parent_mesh = false
    positions = '0 0 0'
    input_files = '01_sub_cp.i'
    execute_on = 'TIMESTEP_BEGIN'
    # output_in_position = true
    sub_cycling = true
  [../]
[]

[Transfers]
  # [./push_C1111]
  #   type = MultiAppCopyTransfer # uses the same mesh
  #   to_multi_app = sub_cp
  #   source_variable = C1111
  #   variable = sub_C1111
  # [../]
  # [./push_euler_angle_1]
  #   type = MultiAppCopyTransfer # uses the same mesh
  #   to_multi_app = sub_cp
  #   source_variable = euler_angle_1
  #   variable = sub_euler_angle_1
  # [../]
  # [./push_euler_angle_2]
  #   type = MultiAppCopyTransfer # uses the same mesh
  #   to_multi_app = sub_cp
  #   source_variable = euler_angle_2
  #   variable = sub_euler_angle_2
  # [../]
  # [./push_euler_angle_3]
  #   type = MultiAppCopyTransfer # uses the same mesh
  #   to_multi_app = sub_cp
  #   source_variable = euler_angle_3
  #   variable = sub_euler_angle_3
  # [../]
  [./push_gr0]
    type = MultiAppCopyTransfer # uses the same mesh
    to_multi_app = sub_cp
    source_variable = gr0
    variable = gr0
  [../]
  [./push_gr1]
    type = MultiAppCopyTransfer # uses the same mesh
    to_multi_app = sub_cp
    source_variable = gr1
    variable = gr1
  [../]
  [./pull_dfe_dgr0]
    type = MultiAppCopyTransfer # uses the same mesh
    from_multi_app = sub_cp
    source_variable = df_elastic_dgr0
    variable = df_elastic_dgr0
  [../]
  [./pull_dfe_dgr1]
    type = MultiAppCopyTransfer # uses the same mesh
    from_multi_app = sub_cp
    source_variable = df_elastic_dgr1
    variable = df_elastic_dgr1
  [../]
[]