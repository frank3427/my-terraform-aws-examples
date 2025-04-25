# ---- AMI for Ubuntu 22.04 on ARM64 architecture
data aws_ami ubuntu_2204_arm64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-202*"]
  }

   owners = ["amazon"]
}

# ---- AMI for Ubuntu 22.04 on X86_64 architecture
data aws_ami ubuntu_2204_x86_64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-202*"]
  }

   owners = ["amazon"]
}

# ---- AMI for Amazon Linux 2023 on ARM64 architecture
data aws_ami al_arm64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-202*-arm64"]
  }
   owners = ["amazon"]
}

# ---- AMI for Amazon Linux 2023 on X86_64 architecture
data aws_ami al_x86_64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-202*-x86_64"]
#    values = ["amzn2-ami-kernel-5.10-hvm-2.0.202*x86_64-gp2"]  # AL2
  }
   owners = ["amazon"]
}
