#include "CalculateMisorientationAngle.h"

misoriAngle_isTwining
CalculateMisorientationAngle::calculateMisorientaion(EulerAngles & Euler1, EulerAngles & Euler2, misoriAngle_isTwining & s, const std::string & CrystalType, Real degree)
{
  Real tolerance_mis = 3.90;
  const quatReal & q1 = Euler1.toQuaternion();
  const quatReal & q2 = Euler2.toQuaternion();
  const quatReal mori_q1q2 = itimesQuaternion(q1, q2); // inv(q1)*q2

  const std::vector<quatReal> q3_twin = getKeyQuat("getTwinning");
  std::vector<quatReal> qcs = getKeyQuat("getCSymm", CrystalType);
  std::vector<quatReal> qss = getKeyQuat("getSSymm");

  // calculate misorientation angle
  s.misor = (Real)(2.0*std::acos(dotQuaternion(q1, q2, qcs, qss)))/degree;  

  for (unsigned i = 0; i < q3_twin.size(); ++i)
  {
    Real misor_twinning = (Real)(2.0*std::acos(dotQuaternion(mori_q1q2, q3_twin[i], qcs, qcs)))/degree;
    s.isTwinning = (misor_twinning < tolerance_mis); // Judging whether it is a twin boundary

    // Determine which type of twin boundary 0 ~ TT1 (tensile twins), 1 ~ CT1 (compression twins)
    if (s.isTwinning) 
    {
      s.twinType = "twin_type" + std::to_string(i); 
      break;
    }
  }
  return s;
}

std::vector<quatReal>
CalculateMisorientationAngle::getKeyQuat(const std::string & QuatType, const std::string & CrystalType)
{
  std::vector<std::vector<Real>> q_num;

  if ( QuatType == "getTwinning" )
    q_num = {
      {0.73728,  0.58508,  0.3378,  0},
      {0.84339,  0.53730,  0,       0}
    }; // Quaternion for HCP twinning from MTEX;
  else if ( QuatType == "getSSymm" )
    q_num = {
      {-1.000e+00,  0.000e+00,  0.000e+00, -2.220e-16}
    }; // from MTEX;  
  else if ( QuatType == "getCSymm" && CrystalType == "hcp")
    q_num = {
      { 1.000e+00,  0.000e+00,  0.000e+00,  0.000e+00},
      { 0.000e+00,  8.660e-01, -5.000e-01,  0.000e+00},
      { 8.660e-01,  0.000e+00,  0.000e+00,  5.000e-01},
      { 0.000e+00,  5.000e-01, -8.660e-01,  0.000e+00},
      { 5.000e-01,  0.000e+00,  0.000e+00,  8.660e-01},
      { 0.000e+00,  0.000e+00, -1.000e+00,  0.000e+00},
      { 0.000e+00,  0.000e+00,  0.000e+00,  1.000e+00},
      { 0.000e+00, -5.000e-01, -8.660e-01,  0.000e+00},
      {-5.000e-01,  0.000e+00,  0.000e+00,  8.660e-01},
      { 0.000e+00, -8.660e-01, -5.000e-01,  0.000e+00},
      {-8.660e-01,  0.000e+00,  0.000e+00,  5.000e-01},
      { 0.000e+00, -1.000e+00,  0.000e+00,  0.000e+00}
    }; // 12 symmetric for hcp
  else if ( QuatType == "getCSymm" && CrystalType == "fcc")
    q_num = {
      { 1.000E+00,	 0.000E+00, 	 0.000E+00, 	 0.000E+00},
      { 5.000E-01,	 5.000E-01, 	 5.000E-01, 	 5.000E-01},
      {-5.000E-01,	 5.000E-01, 	 5.000E-01, 	 5.000E-01},
      { 6.123E-17,	 7.071E-01, 	 7.071E-01, 	 8.660E-17},
      {-7.071E-01,	 1.543E-16, 	 7.071E-01, 	 9.881E-17},
      {-7.071E-01,	-7.071E-01, 	 2.343E-16, 	 1.221E-17},
      { 7.071E-01,	 0.000E+00, 	 0.000E+00, 	 7.071E-01},
      { 1.110E-16,	 7.071E-01, 	 3.925E-17, 	 7.071E-01},
      {-7.071E-01,	 7.071E-01, 	 5.551E-17, 	 2.680E-16},
      {-1.793E-17,	 1.000E+00, 	 8.865E-17, 	 1.045E-16},
      {-5.000E-01,	 5.000E-01, 	 5.000E-01, 	-5.000E-01},
      {-5.000E-01,	-5.000E-01, 	 5.000E-01, 	-5.000E-01},
      { 6.123E-17,	 0.000E+00, 	 0.000E+00, 	 1.000E+00},
      {-5.000E-01,	 5.000E-01, 	-5.000E-01, 	 5.000E-01},
      {-5.000E-01,	 5.000E-01, 	-5.000E-01, 	-5.000E-01},
      {-8.660E-17,	 7.071E-01, 	-7.071E-01, 	 6.123E-17},
      {-1.421E-16,	 7.071E-01, 	-1.110E-16, 	-7.071E-01},
      {-5.551E-17,	 1.910E-16, 	 7.071E-01, 	-7.071E-01},
      {-7.071E-01,	 0.000E+00, 	 0.000E+00, 	 7.071E-01},
      {-7.071E-01,	 7.177E-17, 	-7.071E-01, 	 1.340E-16},
      {-3.005E-16,	 5.551E-17, 	-7.071E-01, 	-7.071E-01},
      {-1.045E-16,	 1.009E-16, 	-1.000E+00, 	-1.793E-17},
      { 5.000E-01,	 5.000E-01, 	-5.000E-01, 	-5.000E-01},
      { 5.000E-01,	 5.000E-01, 	 5.000E-01, 	-5.000E-01}
    }; // 24 symmetric for fcc

  std::vector<quatReal> q(q_num.size());
  for (unsigned int i = 0; i < q_num.size(); ++i)
  {
    q[i].w() = q_num[i][0];
    q[i].x() = q_num[i][1];
    q[i].y() = q_num[i][2];
    q[i].z() = q_num[i][3];
  }
  return q;
}

Real
CalculateMisorientationAngle::dotQuaternion(const quatReal & o1, const quatReal & o2, 
                                            const std::vector<quatReal> & qcs, 
                                            const std::vector<quatReal> & qss)
{
  Real d = 0.0; // used to get misorientation angle
  quatReal mori = itimesQuaternion(o1, o2);

  if (qss.size() <= 1)
    d = dotOuterQuaternion(mori, qcs); 
  else
    d = mtimes2Quaternion(o1, qcs, o2); // mtimesQuaternion(qss,mtimesQuaternion(o1,qcs,0),1)

  return d;
}

quatReal
CalculateMisorientationAngle::itimesQuaternion(const quatReal & q1, const quatReal & q2)
{
  Real a1, b1, c1, d1;
  Real a2, b2, c2, d2;

  a1 = q1.w(); b1 = -q1.x(); c1 = -q1.y(); d1 = -q1.z();
  a2 = q2.w(); b2 = q2.x(); c2 = q2.y(); d2 = q2.z();

  // standart algorithm
  quatReal q;
  q.w() = a1 * a2 - b1 * b2 - c1 * c2 - d1 * d2;
  q.x() = b1 * a2 + a1 * b2 - d1 * c2 + c1 * d2;
  q.y() = c1 * a2 + d1 * b2 + a1 * c2 - b1 * d2;
  q.z() = d1 * a2 - c1 * b2 + b1 * c2 + a1 * d2;

  return q;
}

Real
CalculateMisorientationAngle::dotOuterQuaternion(const quatReal & rot1, const std::vector<quatReal> & rot2)
{
  std::vector<Real> d_vec(rot2.size());

  for (unsigned int i = 0; i < rot2.size(); ++i)
    d_vec[i] = std::abs(rot1.w()*rot2[i].w() + rot1.x()*rot2[i].x() + rot1.y()*rot2[i].y() + rot1.z()*rot2[i].z()); // rot1 * rot2'

  Real d = *std::max_element(d_vec.begin(), d_vec.end());

  return d;
}

Real
CalculateMisorientationAngle::mtimes2Quaternion(const quatReal & q1, const std::vector<quatReal> & q2, const quatReal & qTwin)
{
  // step 1 -- q1-o1(1*4), q2'-qcs'(4*12)
  std::vector<quatReal> q_s1(q2.size());
  for (unsigned int j = 0; j < q2.size(); ++j)
  {
    q_s1[j].w() = q1.w()*q2[j].w() - q1.x()*q2[j].x() - q1.y()*q2[j].y() - q1.z()*q2[j].z();
    q_s1[j].x() = q1.x()*q2[j].w() + q1.w()*q2[j].x() - q1.z()*q2[j].y() + q1.y()*q2[j].z();
    q_s1[j].y() = q1.y()*q2[j].w() + q1.z()*q2[j].x() + q1.w()*q2[j].y() - q1.x()*q2[j].z();
    q_s1[j].z() = q1.z()*q2[j].w() - q1.y()*q2[j].x() + q1.x()*q2[j].y() + q1.w()*q2[j].z();
  }

  // step 2 -- q1-qcs(12*4), q2'-q_s1'(1*12)
  std::vector<std::vector<quatReal>> q_s2(q2.size());
  for (unsigned int i = 0; i < q2.size(); ++i)
    q_s2[i].resize(q2.size());

  for (unsigned int i = 0; i < q2.size(); ++i)
    for (unsigned int j = 0; j < q2.size(); ++j)
    {
      q_s2[i][j].w() = q2[i].w()*q_s1[j].w() - q2[i].x()*q_s1[j].x() - q2[i].y()*q_s1[j].y() - q2[i].z()*q_s1[j].z();
      q_s2[i][j].x() = q2[i].x()*q_s1[j].w() + q2[i].w()*q_s1[j].x() - q2[i].z()*q_s1[j].y() + q2[i].y()*q_s1[j].z();
      q_s2[i][j].y() = q2[i].y()*q_s1[j].w() + q2[i].z()*q_s1[j].x() + q2[i].w()*q_s1[j].y() - q2[i].x()*q_s1[j].z();
      q_s2[i][j].z() = q2[i].z()*q_s1[j].w() - q2[i].y()*q_s1[j].x() + q2[i].x()*q_s1[j].y() + q2[i].w()*q_s1[j].z();      
    }
  
  // inline dot_outer(o1,o2) and find max d_vec
  Real d_max = 0.0;
  std::vector<std::vector<Real>> d_vec(q2.size());
  for (unsigned int i = 0; i < q2.size(); ++i)
    d_vec[i].resize(q2.size());

  for (unsigned int i = 0; i < q2.size(); ++i)
    for (unsigned int j = 0; j < q2.size(); ++j)
    {
      d_vec[i][j] = std::abs(qTwin.w()*q_s2[i][j].w() + qTwin.x()*q_s2[i][j].x() + qTwin.y()*q_s2[i][j].y() + qTwin.z()*q_s2[i][j].z());
      if (d_max < d_vec[i][j])
        d_max = d_vec[i][j];
    }
  return d_max;
}