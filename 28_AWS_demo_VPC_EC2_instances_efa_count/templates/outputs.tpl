
  Wait a few minutes so that post-provisioning scripts can run on the compute instances
  Then you can use instructions below to connect

  ---- SSH connection to Linux EC2 instances
  Run one of following commands on your Linux/MacOS desktop/laptop

%{ for eip in eips ~}
  ssh -F sshcfg d28-inst${1+index(eips,eip)}             
%{ endfor ~}

  ---- Check EFA is present and see OpenMPI version
  Once connected, run the following commands:

  fi_info -p efa -t FI_EP_RDM        to check EFA is present
  mpirun --version                   to check OpenMPI version

  ---- Inter-instance SSH is pre-configured (no manual step needed)
  The Terraform SSH private key is deployed to all instances.
  From any instance, you can SSH to another via EFA IPs:
    ssh 192.168.7.11
    ssh 192.168.7.12

  ---- Test EFA communication between 2 instances
  Option 1: fi_pingpong (libfabric level)
    On instance 1:  fi_pingpong -p efa -e rdm
    On instance 2:  fi_pingpong -p efa -e rdm 192.168.7.11

  Option 2: MPI (from any instance)
    mpirun --hostfile ~/hostfile -n 2 --map-by node \
      -x FI_PROVIDER=efa -x LD_LIBRARY_PATH \
      /opt/amazon/openmpi/bin/mpi_ring

  ---- Or run the helper script
  ~/test_efa.sh
