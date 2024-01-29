################################################
########## Ref #################################
################################################
# 1. bicrystal.i
# 2. exception.i


# 1. 在同一个网格下面，运行
# 2. 采用同一套表征微结构的参数
# 3. main-pf 可以调用 sub-cp 模型

# name = 'step01_multiApp'

################################################
########## MultiApp Factory ####################
################################################

################################################
########## MESH ################################
################################################

i_mesh_x = 25
i_mesh_y = 10
cp_clone_mesh = false

#################################################
########## Material / Model Parameters ##########
#################################################

################################################
########## Solver ##############################
################################################

################################################
########## MESH ################################
################################################

[MultiApps]
  [sub_cp]
    type = TransientMultiApp # FullSolveMultiApp
    # app_type = TensorMechanicsApp

    clone_parent_mesh = ${cp_clone_mesh}
    positions = '0 0 0'
    input_files = '01_sub_cp.i'
  []
[]

[Transfers]
  # [push_u]
  #   type = MultiAppCopyTransfer
  #   source_variable = euler_angle_1
  #   variable = euler_angle_1
  #   to_multi_app = sub_cp
  # []

  [push_eulers]
    type = MultiAppGeneralFieldShapeEvaluationTransfer
    to_multi_app = sub_cp
    source_variable = 'euler_angle_1 euler_angle_2 euler_angle_3'
    variable = 'euler_angle_1 euler_angle_2 euler_angle_3'
  []
  # [pull_elastic_energy]
  #   type = MultiAppGeneralFieldShapeEvaluationTransfer
  #   from_multi_app = micro
  #   variable = vt
  #   postprocessor = average_v
  # []
[]

[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = ${i_mesh_x}
  ny = ${i_mesh_y}
  xmax = 1000
  ymax = 1000
  elem_type = QUAD4
  uniform_refine = 2
[]

[GlobalParams]
  op_num = 2
  var_name_base = gr
[]

[Variables]
  [./PolycrystalVariables]
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
  [./unique_grains]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./var_indices]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./active_bounds_elemental]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [euler_angles]
    order = FIRST
    family = LAGRANGE_VEC
  []
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
  [./unique_grains]
    type = FeatureFloodCountAux
    variable = unique_grains
    flood_counter = grain_tracker
    execute_on = 'initial timestep_begin'
    field_display = UNIQUE_REGION
  [../]
  [./var_indices]
    type = FeatureFloodCountAux
    variable = var_indices
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
  [euler_angles]
    type = OutputEulerAnglesVector
    variable = euler_angles
    euler_angle_provider = euler_angle_file
    grain_tracker = grain_tracker
  []
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
    GBmob0 = 2.5e-6 #m^4/(Js) from Schoenfelder 1997
    Q = 0.23 #Migration energy in eV
    GBenergy = 0.708 #GB energy in J/m^2
    time_scale = 1.0e-6
  [../]
[]

[UserObjects]
  [./euler_angle_file]
    type = EulerAngleFileReader
    file_name = test.tex
  [../]
  [./grain_tracker]
    type = GrainTrackerElasticity
    connecting_threshold = 0.05
    compute_var_to_feature_map = true
    flood_entity_type = elemental
    execute_on = 'initial timestep_begin'

    euler_angle_provider = euler_angle_file
    fill_method = symmetric9
    C_ijkl = '1.27e5 0.708e5 0.708e5 1.27e5 0.708e5 1.27e5 0.7355e5 0.7355e5 0.7355e5'

    outputs = none
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
   coupled_groups = 'gr0,gr1'
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
  nl_rel_tol = 1e-9

  start_time = 0.0
  num_steps = 5
  dt = 0.05

  # [./Adaptivity]
  #  initial_adaptivity = 2
  #   refine_fraction = 0.7
  #   coarsen_fraction = 0.1
  #   max_h_level = 2
  # [../]
[]

[Outputs]
  execute_on = 'timestep_end'
  exodus = true
[]
