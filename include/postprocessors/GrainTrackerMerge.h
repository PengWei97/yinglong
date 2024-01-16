// Added function: When misorientation is below a certain threshold, grains merge

#pragma once

#include "GrainTrackerNew.h"
#include "EulerAngleProvider.h"
#include "MisoriAngleCalculator.h"

class GrainTrackerMerge : public GrainTrackerNew
{
public:
  static InputParameters validParams();

  GrainTrackerMerge(const InputParameters & parameters);

protected:
  // re-merge grains due to misorientation angle from euler angles calculation
  virtual void mergeGrainsBasedMisorientation() override;

  // remap grain with the same Grain ID
  virtual void remapMisorientedGrains() override;

  const EulerAngleProvider & _euler;

  // used to store orientation structure, including misorientation angle, istwinnig, twinning type;
  MisorientationAngleData _misori_s;
};