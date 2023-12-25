#include "GrainTrackerNew.h"

registerMooseObject("yinglongApp", GrainTrackerNew);

InputParameters
GrainTrackerNew::validParams()
{
  InputParameters params = GrainTracker::validParams();
  params.addClassDescription("Grain Tracker derived object for adding a function to considering "
                             "the number of adjacent grains.");
  return params;
}

GrainTrackerNew::GrainTrackerNew(const InputParameters & parameters) : GrainTracker(parameters) {}

void
GrainTrackerNew::createAdjacentIDVector()
{

  for (const auto grain_num_i : index_range(_feature_sets))
  {
    auto & grain_i = _feature_sets[grain_num_i];

    _feature_id_to_index_maps[grain_i._id] = grain_num_i;

    if (grain_i._status == Status::INACTIVE)
      continue;

    for (const auto grain_num_j : index_range(_feature_sets))
    {
      auto & grain_j = _feature_sets[grain_num_j];

      if (grain_i._id < grain_j._id && grain_j._status != Status::INACTIVE &&
          grain_i.boundingBoxesIntersect(grain_j) && grain_i.halosIntersect(grain_j))
      {
        grain_i._adjacent_id.push_back(
            grain_j._id); // It should be noted here that feature ID is stored,
        grain_j._adjacent_id.push_back(grain_i._id); // not _feature_sets index
      }
    }

    std::sort(grain_i._adjacent_id.begin(), grain_i._adjacent_id.end());
  }
}
