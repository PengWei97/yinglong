#pragma once

#include "GBAnisotropyMOP1.h"
#include "MooseMesh.h"

#include <fstream>

registerMooseObject("yinglongApp", GBAnisotropyMOP1);

InputParameters
GBAnisotropyMOP1::validParams()
{
  InputParameters params = Material::validParams();
  params.addCoupledVar("T", 300.0, "Temperature in Kelvin");
  params.addParam<Real>("length_scale", 1.0e-9, "Length scale in m, where default is nm");
  params.addParam<Real>("time_scale", 1.0e-9, "Time scale in s, where default is ns");
  params.addRequiredParam<Real>("wGB", "Diffuse GB width in nm");
  params.addParam<Real>("molar_volume_value",
                        7.11e-6,
                        "molar volume of material in m^3/mol, by default it's the value of copper");
  params.addParam<Real>(
      "delta_sigma", 0.1, "factor determining inclination dependence of GB energy");
  params.addParam<Real>(
      "delta_mob", 0.1, "factor determining inclination dependence of GB mobility");
  params.addRequiredParam<FileName>("Anisotropic_GB_file_name",
                                    "Name of the file containing: 1)GB mobility prefactor; 2) GB "
                                    "migration activation energy; 3)GB energy");
  params.addRequiredParam<bool>("inclination_anisotropy",
                                "The GB anisotropy inclination would be considered if true");
  params.addRequiredCoupledVarWithAutoBuild(
      "v", "var_name_base", "op_num", "Array of coupled variables");
  return params;
}

GBAnisotropyMOP1::GBAnisotropyMOP1(const InputParameters & parameters)
  : Material(parameters),
    _mesh_dimension(_mesh.dimension()),
    _length_scale(getParam<Real>("length_scale")),
    _time_scale(getParam<Real>("time_scale")),
    _M_V(getParam<Real>("molar_volume_value")),
    _delta_sigma(getParam<Real>("delta_sigma")),
    _delta_mob(getParam<Real>("delta_mob")),
    _Anisotropic_GB_file_name(getParam<FileName>("Anisotropic_GB_file_name")),
    _inclination_anisotropy(getParam<bool>("inclination_anisotropy")),
    _T(coupledValue("T")),
    _kappa(declareProperty<Real>("kappa_op")),
    _gamma(declareProperty<Real>("gamma_asymm")),
    _L(declareProperty<Real>("L")),
    _mu(declareProperty<Real>("mu")),
    _molar_volume(declareProperty<Real>("molar_volume")),
    _entropy_diff(declareProperty<Real>("entropy_diff")),
    _act_wGB(declareProperty<Real>("act_wGB")),
    _kb(8.617343e-5),      // Boltzmann constant in eV/K
    _JtoeV(6.24150974e18), // Joule to eV conversion
    _mu_qp(0.0),
    _op_num(coupledComponents("v")),
    _vals(coupledValues("v")),
    _grad_vals(coupledGradients("v")),
    _wGB(getParam<Real>("wGB"))
{
  // reshape vectors
  _sigma.resize(_op_num);
  _mob.resize(_op_num);
  _Q.resize(_op_num);
  _kappa_gamma.resize(_op_num);
  _a_g2.resize(_op_num);

  for (unsigned int op = 0; op < _op_num; ++op)
  {
    _sigma[op].resize(_op_num);
    _mob[op].resize(_op_num);
    _Q[op].resize(_op_num);
    _kappa_gamma[op].resize(_op_num);
    _a_g2[op].resize(_op_num);
  }
}

void
GBAnisotropyMOP1::computeQpProperties()
{
  getGBAnisotropyFromFile();

  computerModelParameter();

  Real sum_kappa = 0.0;
  Real sum_gamma = 0.0;
  Real sum_L = 0.0;
  Real Val = 0.0;
  Real sum_val = 0.0;
  Real f_sigma = 1.0;
  Real f_mob = 1.0;
  Real gamma_value = 0.0;

  for (unsigned int m = 0; m < _op_num - 1; ++m)
  {
    for (unsigned int n = m + 1; n < _op_num; ++n) // m<n
    {
      gamma_value = _kappa_gamma[n][m];

      if (_inclination_anisotropy)
      {
        if (_mesh_dimension == 3)
          mooseError("This material doesn't support inclination dependence for 3D for now!");

        Real phi_ave = libMesh::pi * n / (2.0 * _op_num);
        Real sin_phi = std::sin(2.0 * phi_ave);
        Real cos_phi = std::cos(2.0 * phi_ave);

        Real a = (*_grad_vals[m])[_qp](0) - (*_grad_vals[n])[_qp](0);
        Real b = (*_grad_vals[m])[_qp](1) - (*_grad_vals[n])[_qp](1);
        Real ab = a * a + b * b + 1.0e-7; // for the sake of numerical convergence, the smaller the
                                          // more accurate, but more difficult to converge

        Real cos_2phi = cos_phi * (a * a - b * b) / ab + sin_phi * 2.0 * a * b / ab;
        Real cos_4phi = 2.0 * cos_2phi * cos_2phi - 1.0;

        f_sigma = 1.0 + _delta_sigma * cos_4phi;
        f_mob = 1.0 + _delta_mob * cos_4phi;

        Real g2 = _a_g2[n][m] * f_sigma;
        Real y = -5.288 * g2 * g2 * g2 * g2 - 0.09364 * g2 * g2 * g2 + 9.965 * g2 * g2 -
                 8.183 * g2 + 2.007;
        gamma_value = 1.0 / y;
      }

      Val = (100000.0 * ((*_vals[m])[_qp]) * ((*_vals[m])[_qp]) + 0.01) *
            (100000.0 * ((*_vals[n])[_qp]) * ((*_vals[n])[_qp]) + 0.01);

      sum_val += Val;
      sum_kappa += _kappa_gamma[m][n] * f_sigma * Val;
      sum_gamma += gamma_value * Val;
      // Following comes from substituting Eq. (36c) from the paper into (36b)
      sum_L += Val * _mob[m][n] * std::exp(-_Q[m][n] / (_kb * _T[_qp])) * f_mob * _mu_qp *
               _a_g2[n][m] / _sigma[m][n];
    }
  }

  _kappa[_qp] = sum_kappa / sum_val;
  _gamma[_qp] = sum_gamma / sum_val;
  _L[_qp] = sum_L / sum_val;
  _mu[_qp] = _mu_qp;

  _molar_volume[_qp] =
      _M_V / (_length_scale * _length_scale * _length_scale); // m^3/mol converted to ls^3/mol
  _entropy_diff[_qp] = 9.5 * _JtoeV;                          // J/(K mol) converted to eV(K mol)
  _act_wGB[_qp] = 0.5e-9 / _length_scale;                     // 0.5 nm
}


void 
GBAnisotropyMOP1::getGBAnisotropyFromFile()
{
  // Read in data from "Anisotropic_GB_file_name"
  std::ifstream inFile(_Anisotropic_GB_file_name.c_str());

  if (!inFile)
    paramError("Anisotropic_GB_file_name", "Can't open GB anisotropy input file");

  for (unsigned int i = 0; i < 2; ++i)
    inFile.ignore(255, '\n'); // ignore line

  Real data;
  for (unsigned int i = 0; i < 3 * _op_num; ++i)
  {
    std::vector<Real> row; // create an empty row of double values
    for (unsigned int j = 0; j < _op_num; ++j)
    {
      inFile >> data;
      row.push_back(data);
    }

    if (i < _op_num)
      _sigma[i] = row; // unit: J/m^2

    else if (i < 2 * _op_num)
      _mob[i - _op_num] = row; // unit: m^4/(J*s)

    else
      _Q[i - 2 * _op_num] = row; // unit: eV
  }

  inFile.close();
}

void
GBAnisotropyMOP1::computerModelParameter()
{
  Real sigma_init;
  Real g2 = 0.0;
  Real f_interf = 0.0;
  Real a_0 = 0.75;
  Real a_star = 0.0;
  Real kappa_star = 0.0;
  Real gamma_star = 0.0;
  Real y = 0.0; // 1/gamma
  Real yyy = 0.0;

  Real sigma_big = 0.0;
  Real sigma_small = 0.0;

  for (unsigned int m = 0; m < _op_num - 1; ++m)
    for (unsigned int n = m + 1; n < _op_num; ++n)
    {
      // Convert units of mobility and energy
      _sigma[m][n] *= _JtoeV * (_length_scale * _length_scale); // eV/nm^2

      _mob[m][n] *= _time_scale / (_JtoeV * (_length_scale * _length_scale * _length_scale *
                                             _length_scale)); // Convert to nm^4/(eV*ns);

      if (m == 0 && n == 1)
      {
        sigma_big = _sigma[m][n];
        sigma_small = sigma_big;
      }

      else if (_sigma[m][n] > sigma_big)
        sigma_big = _sigma[m][n];

      else if (_sigma[m][n] < sigma_small)
        sigma_small = _sigma[m][n];
    }

  sigma_init = (sigma_big + sigma_small) / 2.0;
  _mu_qp = 6.0 * sigma_init / _wGB;

  for (unsigned int m = 0; m < _op_num - 1; ++m)
    for (unsigned int n = m + 1; n < _op_num; ++n) // m<n
    {

      a_star = a_0;
      a_0 = 0.0;

      while (std::abs(a_0 - a_star) > 1.0e-9)
      {
        a_0 = a_star;
        kappa_star = a_0 * _wGB * _sigma[m][n];
        g2 = _sigma[m][n] * _sigma[m][n] / (kappa_star * _mu_qp);

        // y = -5.288 * g2 * g2 * g2 * g2 - 0.09364 * g2 * g2 * g2 + 9.965 * g2 * g2 - 8.183 * g2 + 2.007; // MOOSE
        y = -3.0944 * g2 * g2 * g2 * g2 - 1.8169 * g2 * g2 * g2 + 10.323 * g2 * g2 - 8.1819 * g2 + 2.0033; // MD2022

        gamma_star = 1 / y;
        yyy = y * y * y;

        // f_interf = 0.05676 * yyy * yyy - 0.2924 * yyy * y * y + 0.6367 * yyy * y - 0.7749 * yyy + 0.6107 * y * y - 0.4324 * y + 0.2792; // MOOSE       
        f_interf = 0.078815 * yyy * yyy - 0.49546 * yyy * y * y + 1.2244 * yyy * y - 1.5281 * yyy + 1.0686 * y * y - 0.55631 * y + 0.29067; // MD2022
        a_star = std::sqrt(f_interf / g2);
      }

      _kappa_gamma[m][n] = kappa_star; // upper triangle stores the discrete set of kappa values
      _kappa_gamma[n][m] = gamma_star; // lower triangle stores the discrete set of gamma values

      _a_g2[m][n] = a_star; // upper triangle stores "a" data.
      _a_g2[n][m] = g2;     // lower triangle stores "g2" data.
    }  
}
