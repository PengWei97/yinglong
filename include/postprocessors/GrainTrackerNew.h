// Added function: When misorientation is below a certain threshold, grains merge

#pragma once

#include "GrainTracker.h"

class GrainTrackerNew : public GrainTracker
{
public:
  static InputParameters validParams();

  GrainTrackerNew(const InputParameters & parameters);

protected:
  // establish the vector of adjacent grains based on the topological relationship
  virtual void createAdjacentIDVector() override;

  // This data structure is used to store the mapping from Grain ID to index in feature sets
  std::map<unsigned int, std::size_t> _feature_id_to_index_maps;
};