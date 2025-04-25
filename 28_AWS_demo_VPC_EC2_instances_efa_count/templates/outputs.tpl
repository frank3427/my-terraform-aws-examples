
  Wait a few minutes so that post-provisioning scripts can run on the compute instances
  Then you can use instructions below to connect

  ---- SSH connection to Linux EC2 instances
  Run one of following commands on your Linux/MacOS desktop/laptop

%{ for eip in eips ~}
  ssh -F sshcfg d28-inst${1+index(eips,eip)}             
%{ endfor ~}

  ---- Check EFS is present and see OpenMPI version
  Once connected, run the following commands:

  fi_info -p efa -t FI_EP_RDM         to check EFA is present
  mpirun -version                     to check OpenMPI version
  