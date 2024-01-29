//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "OutputEulerAnglesVector.h"
#include "GrainTracker.h"
#include "EulerAngleProvider.h"

registerMooseObject("yinglongApp", OutputEulerAnglesVector);

InputParameters
OutputEulerAnglesVector::validParams()
{
  InputParameters params = VectorAuxKernel::validParams();
  params.addClassDescription("Output Euler angles from user object to an AuxVariable.");
  params.addRequiredParam<UserObjectName>("euler_angle_provider",
                                          "Name of Euler angle provider user object");
  params.addRequiredParam<UserObjectName>("grain_tracker",
                                          "The GrainTracker UserObject to get values from.");
  return params;
}

OutputEulerAnglesVector::OutputEulerAnglesVector(const InputParameters & parameters)
  : VectorAuxKernel(parameters),
    _euler(getUserObject<EulerAngleProvider>("euler_angle_provider")),
    _grain_tracker(getUserObject<GrainTracker>("grain_tracker"))
{
}

void
OutputEulerAnglesVector::precalculateValue()
{
  // ID of unique grain at current point
  const auto grain_id =
      _grain_tracker.getEntityValue((isNodal() ? _current_node->id() : _current_elem->id()),
                                    FeatureFloodCount::FieldType::UNIQUE_REGION,
                                    0);

  // Recover euler angles for current grain
  RealVectorValue angles;
  if (grain_id >= 0)
    angles = _euler.getEulerAngles(grain_id);

  // Return euler angles
  _value_vectors = angles;
}

RealVectorValue
OutputEulerAnglesVector::computeValue()
{
  return _value_vectors;
}
