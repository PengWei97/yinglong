//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "ElasticDeformationEnergyAux.h"

registerMooseObject("yinglongApp", ElasticDeformationEnergyAux);

InputParameters
ElasticDeformationEnergyAux::validParams()
{
  InputParameters params = AuxKernel::validParams();
  params.addClassDescription("Compute the local elastic energy");
  params.addParam<std::string>("base_name", "Mechanical property base name");
  return params;
}

ElasticDeformationEnergyAux::ElasticDeformationEnergyAux(const InputParameters & parameters)
  : AuxKernel(parameters),
    _base_name(isParamValid("base_name") ? getParam<std::string>("base_name") + "_" : ""),
    _pk2(getMaterialProperty<RankTwoTensor>("second_piola_kirchhoff_stress")),
    _total_lagrangian_strain(getMaterialProperty<RankTwoTensor>("total_lagrangian_strain"))
{
}

Real
ElasticDeformationEnergyAux::computeValue()
{
  return 0.5 * _pk2[_qp].doubleContraction(_total_lagrangian_strain[_qp]);
}
