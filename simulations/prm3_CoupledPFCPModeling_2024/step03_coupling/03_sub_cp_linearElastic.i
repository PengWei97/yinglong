my_filename = "sub_cp_linear"

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
  displacements = 'ux uy'
  var_name_base = gr
  op_num = 2
  use_displaced_mesh = true

  length_scale = 1.0e-9
  pressure_scale = 1.0e6
[]

[Variables]
  [./ux]
    order = FIRST
    family = LAGRANGE
  [../]
  [./uy]
    order = FIRST
    family = LAGRANGE
  [../]
[]

[Kernels]
  [./TensorMechanics]
    displacements = 'ux uy'
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
    flood_entity_type = ELEMENTAL
    execute_on = 'timestep_begin'

    euler_angle_provider = euler_angle_file
    C_ijkl = '1.27e5 0.708e5 0.708e5 1.27e5 0.708e5 1.27e5 0.7355e5 0.7355e5 0.7355e5'
    fill_method = symmetric9
    outputs = none
  [../]
[]

[AuxVariables]
  [./marker]
    family = MONOMIAL
    order = CONSTANT
  [../]
  [./grain_ids]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./gr0]
    order = FIRST
    family = LAGRANGE
  [../]
  [./gr1]
    order = FIRST
    family = LAGRANGE
  [../]
  [./f_gr0_grainId]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./f_gr1_grainId]
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
  [./C1111]
   order = CONSTANT
   family = MONOMIAL
  [../]
[]

[AuxKernels]
  [./df_elastic_dgr0]
    type = MaterialRealAux
    property = df_elastic/dgr0
    variable = df_elastic_dgr0
  [../]  
  [./df_elastic_dgr1]
    type = MaterialRealAux
    property = df_elastic/dgr1
    variable = df_elastic_dgr1
  [../]  
  [./grain_ids]
    type = FeatureFloodCountAux
    variable = grain_ids
    flood_counter = grain_tracker
    execute_on = 'initial timestep_begin'
    field_display = UNIQUE_REGION
  [../]
  [./C1111]
    type = RankFourAux
    variable = C1111
    rank_four_tensor = elasticity_tensor
    index_l = 0
    index_j = 0
    index_k = 0
    index_i = 0
    execute_on = timestep_end
  [../]
[]

[BCs]
  [./symmy]
    type = DirichletBC
    variable = uy
    boundary = bottom
    value = 0
  [../]
  [./symmx]
    type = DirichletBC
    variable = ux
    boundary = left
    value = 0
  [../]
  [./tdisp]
    type = FunctionDirichletBC
    variable = uy
    boundary = top
    function = 't'
  [../]
[]

[Materials]  
  [./ElasticityTensor]
    type = ComputePolycrystalElasticityTensor
    block = 0
    grain_tracker = grain_tracker
  [../]
  [./strain]
    type = ComputeSmallStrain
    block = 0
    displacements = 'ux uy'
  [../]
  [./stress]
    type = ComputeLinearElasticStress
    block = 0
  [../]
  [./delasticity_energy_dgrX]
    type = ACGrGrElastiEnergyLinear
  [../]
[]

[Preconditioning]
  [./smp]
    type = SMP
    full = true
  [../]
[]

[Executioner]
  type = Transient
  solve_type = 'PJFNK'

  petsc_options_iname = '-pc_type -pc_asm_overlap -sub_pc_type -ksp_type -ksp_gmres_restart'
  petsc_options_value = ' asm      2              lu            gmres     200'

  l_max_its = 100
  l_tol = 1e-4

  nl_max_its = 30
  nl_abs_tol = 1e-10
  nl_rel_step_tol = 1e-10
  nl_rel_tol = 1e-12
  nl_abs_step_tol = 1e-10
  
  dtmax = 10.0
  # end_time = 100
  dtmin = 0.01
  # num_steps = 1000

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
  [my_exodus]
    type = Nemesis
    file_base = ./${my_filename}/out_${my_filename}
  [../]
  print_linear_residuals = false
[]
