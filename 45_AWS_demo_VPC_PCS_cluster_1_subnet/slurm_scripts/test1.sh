#!/bin/bash
#SBATCH -J test1

echo "This is job name $SLURM_JOB_NAME (job ID $SLURM_JOB_ID)"
echo "Running on $SLURMD_NODENAME"
echo "Submitted from $SLURM_SUBMIT_HOST"

sleep 60

echo "Complete"