#!/bin/bash
#SBATCH -p amd_512
#SBATCH -N 2
#SBATCH -n 256

# mpiexec -n 256 ~/projects/qinglong/qinglong-opt -i GNSoTi_AGG_level2a3_550du.i --recover # v4

# mpiexec -n 256 ~/projects/qinglong/qinglong-opt -i GNSoTi_AGG_level2a3_550du.i --recover # v7

# ./case4_recovery_v3/out_case4_recovery_v3_cp/2201
# tar -cvf - ex_case4_recovery_v71/*.e-s0??[2].* ex_case4_recovery_v71/*.e-s0026.* | pigz -9 -p 20 > ex_case4_recovery_v71.tgz 
# tar -cvf - ex_case4_recovery_v61/*.e-s???[258]* ex_case4_recovery_v61/*.e-s0025.* | pigz -9 -p 20 > ex_case4_recovery_v61.tgz 
# tar -cvf - csv_case4_recovery_v7/* | pigz -9 -p 20 > csv_case4_recovery_v7.tgz 
# tar -cvf - csv_case3_noStored_v1/* | pigz -9 -p 20 > csv_case3_noStored_v1.tgz 
# ll ex_case4_recovery_v72s[12]/*.e-s*.056
# ll ex_case4_recovery_v72s/*.e-s*.056

mpiexec -np 30 ~/projects/yinglong/yinglong-opt -i GNSoTi_AGG_level2a3_550du.i > 01.log
