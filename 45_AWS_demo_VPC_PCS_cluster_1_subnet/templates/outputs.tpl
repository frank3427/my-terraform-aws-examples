---- Copy Slurm scripts to share storage
scp -F ${sshcfg_file} ${scripts_dir}/* d45a-node1:${efs_mntpt}
scp -F ${sshcfg_file} ${scripts_dir}/* d45a-node1:${lustre_mntpt}

---- SSH directly to the computes nodes using the following commands:

%{ for i in range(nb_nodes) ~}
ssh -F ${sshcfg_file} d45a-node${i+1}  
%{ endfor ~}

---- submit test jobs with Slurm sbatch command:
Once connected, run the following commands:

sinfo
squeue
mpirun -version         to check OpenMPI version

cd ${efs_mntpt}
sbatch -p ${slurm_queue} ./test1.sh
sbatch -p ${slurm_queue} ./test1.sh
sbatch -p ${slurm_queue} ./test1.sh
sbatch -p ${slurm_queue} ./test1.sh
sbatch -p ${slurm_queue} ./test1.sh

sinfo
squeue
