[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 20
  ny = 20
  xmin = 0
  xmax = 200
  ymin = 0
  ymax = 200
  elem_type = QUAD4
  
  parallel_type = distributed
[]

[GlobalParams]
  op_num = 5
  var_name_base = gr
[]

[Variables]
  [./PolycrystalVariables]
  [../]
[]

[UserObjects]
  [voronoi]
    type = PolycrystalVoronoi
    grain_num = 5 # Number of grains
    rand_seed = 10
    int_width = 4.0
  []
  [./euler_angle_file]
    type = EulerAngleFileReader
    file_name = grn_5_rand_2D_45.tex
  [../]
  [grain_tracker]
    type = GrainTrackerMerge
    threshold = 0.2
    compute_var_to_feature_map = true
    flood_entity_type = ELEMENTAL

    # TODO - merge有问题，说是问题出在PETSC软件上面
    merge_grains_based_misorientaion = false
    euler_angle_provider = euler_angle_file

    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
[]

[ICs]
  [PolycrystalICs]
    [PolycrystalColoringIC]
      polycrystal_ic_uo = voronoi
    []
  []
[]

[AuxVariables]
  [./bounds_dummy]
    order = FIRST
    family = LAGRANGE
  [../]
  [./bnds]
    order = FIRST
    family = LAGRANGE
  [../]
  [./phi1]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[Kernels]
  [./PolycrystalKernel]
  [../]
[]

[AuxKernels]
  [./BndsCalc]
    type = BndsCalcAux
    variable = bnds
    execute_on = timestep_end
  [../]
  [phi1]
    type = OutputEulerAngles
    variable = phi1
    euler_angle_provider = euler_angle_file
    grain_tracker = grain_tracker
    output_euler_angle = 'phi1'
  []
[]

[BCs]
  [./Periodic]
    [./top_bottom]
      auto_direction = 'x y'
    [../]
  [../]
[]

[Materials]
  [./CuGrGranisotropic]
    type = GBAnisotropyMisori
    T = 450 # Constant temperature of the simulation (for mobility calculation)
    wGB = 4.0 # Width of the diffuse GB
  
    GBmob_HAGB = 2.5e-6 #m^4(Js) for copper from Schoenfelder1997
    GBsigma_HAGB = 0.708 #J/m^2 from Schoenfelder1997

    grain_tracker = grain_tracker
    euler_angle_provider = euler_angle_file

    gb_energy_anisotropy = true
    gb_mobility_anisotropy = true

    output_properties = 'L mu misori_angle'
    outputs = my_exodus
  [../]
[]

[Postprocessors]
  [./dofs]
    type = NumDOFs
  [../]
  [./dt]
    type = TimestepSize
  [../]
  [./run_time]
    type = PerfGraphData
    section_name = "Root"
    data_type = total
  [../]
[]

[Executioner]
  type = Transient
  scheme = bdf2
  solve_type = PJFNK
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart -pc_hypre_boomeramg_strong_threshold'
  petsc_options_value = 'hypre boomeramg 31 0.7'
  l_tol = 1.0e-4
  l_max_its = 30
  nl_max_its = 25
  nl_rel_tol = 1.0e-7

  start_time = 0.0
  num_steps = 5

  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 0.1
    growth_factor = 1.2
    cutback_factor = 0.8
    optimal_iterations = 8
  [../]
  [./Adaptivity]
    initial_adaptivity = 4
    cycles_per_step = 2 # The number of adaptivity cycles per step
    refine_fraction = 0.5 # The fraction of elements or error to refine.
    coarsen_fraction = 0.05
    max_h_level = 4
  [../]
[]

[Outputs]
  csv = true
  [my_exodus]
    type = Nemesis
  [../]
  print_linear_residuals = false
[]