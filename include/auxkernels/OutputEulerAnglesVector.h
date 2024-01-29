//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "AuxKernel.h"
#include "EulerAngleProvider.h"
#include "GrainTracker.h"

// Forward Declarations
class GrainTracker;
class EulerAngleProvider;

/**
 * Output euler angles from user object to an AuxVariable.
 */
class OutputEulerAnglesVector : public VectorAuxKernel
{
public:
  static InputParameters validParams();

  OutputEulerAnglesVector(const InputParameters & parameters);

protected:
  virtual RealVectorValue computeValue() override;
  virtual void precalculateValue();

  /// Object providing the Euler angles
  const EulerAngleProvider & _euler;

  /// Grain tracker object
  const GrainTracker & _grain_tracker;

  /// precalculated element value
  RealVectorValue _value_vectors;
};
