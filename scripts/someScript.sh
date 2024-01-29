mkdir -p /home/pw-moose/projects/yinglong/src/auxkernels/crystal_plasticity/
mkdir -p /home/pw-moose/projects/yinglong/include/auxkernels/crystal_plasticity/

cp /home/pw-moose/projects/moose/modules/tensor_mechanics/src/auxkernels/ElasticEnergyAux.C /home/pw-moose/projects/yinglong/src/auxkernels/ElasticDeformationEnergyAux.C
cp /home/pw-moose/projects/moose/modules/tensor_mechanics/include/auxkernels/ElasticEnergyAux.h /home/pw-moose/projects/yinglong/include/auxkernels/ElasticDeformationEnergyAux.h


code /home/pw-moose/projects/yinglong/src/materials/grain_growth/GBAnisotropyMisoriBase.C
code /home/pw-moose/projects/yinglong/include/materials/grain_growth/GBAnisotropyMisoriBase.h