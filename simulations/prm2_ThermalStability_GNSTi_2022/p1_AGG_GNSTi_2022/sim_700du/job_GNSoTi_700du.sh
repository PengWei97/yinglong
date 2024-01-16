#!/bin/bash
#SBATCH -p amd_512
#SBATCH -N 2
#SBATCH -n 256

mpiexec -n 256 ~/projects/qinglong/qinglong-opt -i GNSoTi_AGG_level2a3_700du.i

# ./case4_recovery_v3/out_case4_recovery_v3_cp/2201
# tar -cvf - ex_case4_recovery_v92/*.e-s0??[2].* ex_case4_recovery_v92/*.e-s0115.* | pigz -9 -p 20 > ex_case4_recovery_v92.tgz 
# tar -cvf - ex_case4_recovery_v92/*.e-s0070.* ex_case4_recovery_v92/*.e-s0101.* | pigz -9 -p 20 > ex_case4_recovery_v92.tgz 
# tar -cvf - csv_case4_recovery_v8/* | pigz -9 -p 20 > csv_case4_recovery_v8.tgz 
# ll csv_case4_recovery_v9/*.e-s*.056
