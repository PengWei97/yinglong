//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "ComputeElasticityTensorCPCoupled.h"
#include "RotationTensor.h"

registerMooseObject("TensorMechanicsApp", ComputeElasticityTensorCPCoupled);

InputParameters
ComputeElasticityTensorCPCoupled::validParams()
{
  InputParameters params = ComputeElasticityTensor::validParams();
  params.addClassDescription("Compute an elasticity tensor for crystal plasticity.");

  params.addCoupledVar("euler_angles_pf_1",
                       "Vector of variable arguments of the euler angles phi1");
  params.addCoupledVar("euler_angles_pf_2", "Vector of variable arguments of the euler angles Phi");
  params.addCoupledVar("euler_angles_pf_3",
                       "Vector of variable arguments of the euler angles phi2");

  params.addParam<UserObjectName>("read_prop_user_object",
                                  "The ElementReadPropertyFile "
                                  "GeneralUserObject to read element "
                                  "specific property values from file");
  return params;
}

ComputeElasticityTensorCPCoupled::ComputeElasticityTensorCPCoupled(
    const InputParameters & parameters)
  : ComputeElasticityTensor(parameters),

    _euler_angle1(coupledValue("euler_angles_pf_1")),
    _euler_angle2(coupledValue("euler_angles_pf_2")),
    _euler_angle3(coupledValue("euler_angles_pf_3")),

    _read_prop_user_object(isParamValid("read_prop_user_object")
                               ? &getUserObject<PropertyReadFile>("read_prop_user_object")
                               : nullptr),
    _Euler_angles_mat_prop(declareProperty<RealVectorValue>("Euler_angles")),
    _crysrot(declareProperty<RankTwoTensor>(_base_name + "crysrot")),
    _R(_Euler_angles)
{
  // the base class guarantees constant in time, but in this derived class the
  // tensor will rotate over time once plastic deformation sets in
  revokeGuarantee(_elasticity_tensor_name, Guarantee::CONSTANT_IN_TIME);

  // the base class performs a passive rotation, but the crystal plasticity
  // materials use active rotation: recover unrotated _Cijkl here
  if (parameters.isParamValid("rotation_matrix"))
  {
    _user_provided_rotation_matrix = true;
    _Cijkl.rotate(_rotation_matrix.transpose());
  }
  else
  {
    _user_provided_rotation_matrix = false;
    _Cijkl.rotate(_R.transpose());
  }

  if (_user_provided_rotation_matrix &&
      (_read_prop_user_object || (parameters.isParamSetByUser("euler_angle_1")) ||
       (parameters.isParamSetByUser("euler_angle_2")) ||
       (parameters.isParamSetByUser("euler_angle_3"))))
    mooseError("Bunge Euler angle information and the rotation_matrix cannot both be specified. "
               "Provide only one type of orientation information in the input file.");
}

void
ComputeElasticityTensorCPCoupled::assignEulerAngles()
{
  if (_read_prop_user_object)
  {
    _Euler_angles_mat_prop[_qp](0) = _read_prop_user_object->getData(_current_elem, 0);
    _Euler_angles_mat_prop[_qp](1) = _read_prop_user_object->getData(_current_elem, 1);
    _Euler_angles_mat_prop[_qp](2) = _read_prop_user_object->getData(_current_elem, 2);
  }
  else
    _Euler_angles_mat_prop[_qp] = _Euler_angles;

  RealVectorValue Euler_angles_tansfor = {
      _euler_angle1[_qp], _euler_angle2[_qp], _euler_angle3[_qp]};

  _Euler_angles_mat_prop[_qp] = Euler_angles_tansfor;
  _R.update(_Euler_angles_mat_prop[_qp]);
}

void
ComputeElasticityTensorCPCoupled::initQpStatefulProperties()
{
  if (!_user_provided_rotation_matrix)
  {
    assignEulerAngles();
    _crysrot[_qp] = _R.transpose();
  }
  else
    _crysrot[_qp] = _rotation_matrix.transpose();
}

void
ComputeElasticityTensorCPCoupled::computeQpElasticityTensor()
{
  // Properties assigned at the beginning of every call to material calculation
  // is required by the monolithic and user object versions. If those classes
  // are deprecated, these update can be removed and save time
  if (!_user_provided_rotation_matrix)
  {
    assignEulerAngles();
    _crysrot[_qp] = _R.transpose();
  }
  else
    _crysrot[_qp] = _rotation_matrix.transpose();

  _elasticity_tensor[_qp] = _Cijkl;
  _elasticity_tensor[_qp].rotate(_crysrot[_qp]);
}
