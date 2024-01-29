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
#include "RankTwoTensor.h"

// Forward declarations

class ElasticDeformationEnergyAux : public AuxKernel
{
public:
  static InputParameters validParams();

  ElasticDeformationEnergyAux(const InputParameters & parameters);
  virtual ~ElasticDeformationEnergyAux() {}

protected:
  virtual Real computeValue();

  /// Base name of the material system used to calculate the elastic energy
  const std::string _base_name;

  /// The stress tensor
  const MaterialProperty<RankTwoTensor> & _pk2;
  const MaterialProperty<RankTwoTensor> & _total_lagrangian_strain;
};
