#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install some packages"
apt-get update
apt-get install -y nmap zsh

echo "========== Install EFA software, including Open MPI"
cd /tmp
curl -O https://efa-installer.amazonaws.com/aws-efa-installer-latest.tar.gz
tar -xf aws-efa-installer-latest.tar.gz
cd aws-efa-installer
./efa_installer.sh -y

# disable ptrace protection (needed for libfabric shared memory provider)
sysctl -w kernel.yama.ptrace_scope=0
echo "kernel.yama.ptrace_scope = 0" >> /etc/sysctl.d/10-ptrace.conf

# Add EFA and OpenMPI to PATH and LD_LIBRARY_PATH for ubuntu user
cat >> /home/ubuntu/.bashrc << 'EOF'
export PATH=$PATH:/opt/amazon/openmpi/bin:/opt/amazon/efa/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/amazon/openmpi/lib:/opt/amazon/efa/lib
EOF

echo "========== Compile MPI ring example"
export PATH=$PATH:/opt/amazon/openmpi/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/amazon/openmpi/lib
cat > /tmp/mpi_ring.c << 'MPIEOF'
#include <stdio.h>
#include <mpi.h>
int main(int argc, char *argv[])
{
    int rank, size, next, prev, message, tag = 201;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    next = (rank + 1) % size;
    prev = (rank + size - 1) % size;
    if (rank == 0) {
        message = 10;
        printf("Process 0 sending %d to %d, tag %d (%d processes in ring)\n",
               message, next, tag, size);
        MPI_Send(&message, 1, MPI_INT, next, tag, MPI_COMM_WORLD);
        MPI_Recv(&message, 1, MPI_INT, prev, tag, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        printf("Process 0 received %d\n", message);
    } else {
        MPI_Recv(&message, 1, MPI_INT, prev, tag, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        printf("Process %d received %d\n", rank, message);
        message--;
        MPI_Send(&message, 1, MPI_INT, next, tag, MPI_COMM_WORLD);
    }
    MPI_Finalize();
    return 0;
}
MPIEOF
mpicc /tmp/mpi_ring.c -o /opt/amazon/openmpi/bin/mpi_ring
rm -f /tmp/mpi_ring.c

echo "========== Setup passwordless SSH between instances"
# Install the shared private key (same key used by Terraform for SSH access)
cat > /home/ubuntu/.ssh/id_rsa << 'PRIVATEKEY'
${ssh_private_key}
PRIVATEKEY
chmod 600 /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa

# Configure SSH to skip host key checking on the private EFA subnet
cat > /home/ubuntu/.ssh/config << 'EOF'
Host 192.168.7.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    IdentityFile ~/.ssh/id_rsa
EOF
chown ubuntu:ubuntu /home/ubuntu/.ssh/config
chmod 600 /home/ubuntu/.ssh/config

echo "========== Create EFA hostfile"
cat > /home/ubuntu/hostfile << 'EOF'
${hostfile_content}
EOF
chown ubuntu:ubuntu /home/ubuntu/hostfile

echo "========== Create EFA test script"
cat > /home/ubuntu/test_efa.sh << 'SCRIPT'
#!/bin/bash
echo "=== Check EFA interface ==="
fi_info -p efa -t FI_EP_RDM

echo ""
echo "=== Check OpenMPI version ==="
mpirun --version

echo ""
echo "=== Run ping-pong latency test between nodes ==="
echo "On instance 1:  fi_pingpong -p efa -e rdm"
echo "On instance 2:  fi_pingpong -p efa -e rdm 192.168.7.11"
echo ""
echo "=== Run MPI ring test between nodes (from any instance) ==="
echo "  mpirun --hostfile ~/hostfile -n 2 --map-by node -x FI_PROVIDER=efa -x LD_LIBRARY_PATH /opt/amazon/openmpi/bin/mpi_ring"
SCRIPT
chown ubuntu:ubuntu /home/ubuntu/test_efa.sh
chmod +x /home/ubuntu/test_efa.sh

echo "========== Done"
# echo "========== Install latest updates"
# apt-get upgrade -y

# echo "========== Final reboot"
# reboot
