# .\Github\moose\modules\tensor_mechanics\test\tests\crystal_plasticity\stress_update_material_based\exception.i

[GlobalParams]
  displacements = 'ux uy'
[]

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
    op_num = 2
    var_name_base = gr
    outputs = none
  [../]
[]

[AuxVariables]
  [./grain_ids]
    order = CONSTANT
    family = MONOMIAL
  [../]
  # [./sub_euler_angle_1]
  #   order = CONSTANT
  #   family = MONOMIAL
  # [../]
  # [./sub_euler_angle_2]
  #   order = CONSTANT
  #   family = MONOMIAL
  # [../]
  # [./sub_euler_angle_3]
  #   order = CONSTANT
  #   family = MONOMIAL
  # [../]
  [./gr0]
    order = FIRST
    family = LAGRANGE
  [../]
  [./gr1]
    order = FIRST
    family = LAGRANGE
  [../]
  [./df_elastic_dgr0]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./df_elastic_dgr1]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./elastic_energy]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./pk2]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./fp_yy]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./rotout]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./e_yy]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./gss]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./slip_increment]
   order = CONSTANT
   family = MONOMIAL
  [../]
  [./C1111]
   order = CONSTANT
   family = MONOMIAL
  [../]
  [./C1212]
   order = CONSTANT
   family = MONOMIAL
  [../]
[]

[Modules/TensorMechanics/Master/all]
  strain = FINITE
  add_variables = true
  generate_output = stress_yy
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
  [./elastic_energy]
    type = ElasticDeformationEnergyAux # ElasticEnergyAux
    variable = elastic_energy
    execute_on = timestep_end
  [../]
  [./fp_yy]
    type = RankTwoAux
    variable = fp_yy
    rank_two_tensor = plastic_deformation_gradient
    index_j = 1
    index_i = 1
    execute_on = timestep_end
  [../]
  [./pk2]
   type = RankTwoAux
   variable = pk2
   rank_two_tensor = second_piola_kirchhoff_stress
   index_j = 1
   index_i = 1
   execute_on = timestep_end
  [../]
  [./e_yy]
    type = RankTwoAux
    variable = e_yy
    rank_two_tensor = total_lagrangian_strain
    index_j = 1
    index_i = 1
    execute_on = timestep_end
  [../]
  [./gss]
    type = MaterialStdVectorAux
    variable = gss
    property = slip_resistance
    index = 0
    execute_on = timestep_end
  [../]
  [./slip_inc]
   type = MaterialStdVectorAux
   variable = slip_increment
   property = slip_increment
   index = 0
   execute_on = timestep_end
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
  [./C1212]
    type = RankFourAux
    variable = C1212
    rank_four_tensor = elasticity_tensor
    index_l = 0
    index_j = 1
    index_k = 0
    index_i = 1
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
  [./elasticity_tensor]
    type = ComputePolycrystalElasticityTensorCP #  Grain_v1 ComputeElasticityTensorCP

    grain_tracker = grain_tracker
    euler_angle_provider = euler_angle_file
    var_name_base = gr
    op_num = 2    
    # outputs = my_exodus
  [../]
  [./stress]
    type = ComputeMultipleCrystalPlasticityStress
    crystal_plasticity_models = 'trial_xtalpl'
    tan_mod_type = exact
    use_line_search = true
    maximum_substep_iteration = 100
    min_line_search_step_size = 0.01
  [../]
  [./trial_xtalpl]
    type = CrystalPlasticityKalidindiUpdate
    number_slip_systems = 12
    slip_sys_file_name = input_slip_sys.tex

    t_sat = 110
    gss_initial = 10

    resistance_tol = 0.01
  [../]
  [./d_elasticity_energy]
    type = ACGrGrElasticDrivingForceCP
    var_name_base = gr
    op_num = 2    
    # outputs = my_exodus
    # output_properties = delasticity_tensor_d
  [../]
[]

[Postprocessors]
  [./stress_yy]
    type = ElementAverageValue
    variable = stress_yy
  [../]
  [./pk2]
   type = ElementAverageValue
   variable = pk2
  [../]
  [./fp_yy]
    type = ElementAverageValue
    variable = fp_yy
  [../]
  [./e_yy]
    type = ElementAverageValue
    variable = e_yy
  [../]
  [./gss]
    type = ElementAverageValue
    variable = gss
  [../]
  [./slip_increment]
   type = ElementAverageValue
   variable = slip_increment
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

  num_steps = 2
  dt = 0.05
[]

[Outputs]
  [my_exodus]
    type = Nemesis
    # sync_times = '0.1 0.5	1	1.5	2	2.5	3	3.5	4	4.5	5	5.5	6	6.5	7	7.5	8	8.5	9	9.5	10	10.5	11	11.5	12	12.5	13	13.5	14	14.5	15	15.5	16	16.5	17	17.5	18 20 30 40 50 60 70 80 90 100'
    # sync_only = true
    interval = 3
  [../]
  print_linear_residuals = false
[]
