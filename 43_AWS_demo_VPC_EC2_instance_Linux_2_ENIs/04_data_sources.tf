# ---- AMI for Amazon Linux 2023 on ARM64 architecture
data aws_ami al2023_arm64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*arm64"]
  }
   owners = ["amazon"]
}

# ---- AMI for Amazon Linux 2023 on X86_64 architecture
data aws_ami al2023_x86_64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*x86_64"]
  }
   owners = ["amazon"]
}

# ---- AMI for Amazon Linux 2 on ARM64 architecture
data aws_ami al2_arm64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.202*arm64-gp2"]
  }
   owners = ["amazon"]
}

# ---- AMI for Amazon Linux 2 on X86_64 architecture
data aws_ami al2_x86_64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.202*x86_64-gp2"]
  }
   owners = ["amazon"]
}

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

locals {
  ami_al_arm64  = (var.linux == "al2023") ? data.aws_ami.al2023_arm64.id       : data.aws_ami.al2_arm64.id
  ami_al_x86_64 = (var.linux == "al2023") ? data.aws_ami.al2023_x86_64.id      : data.aws_ami.al2_x86_64.id
  ami_arm64     = (var.linux == "ubuntu") ? data.aws_ami.ubuntu_2204_arm64.id  : local.ami_al_arm64
  ami_x86_64    = (var.linux == "ubuntu") ? data.aws_ami.ubuntu_2204_x86_64.id : local.ami_al_x86_64
  ami           = (var.arch  == "arm64")  ? local.ami_arm64                    : local.ami_x86_64
}

# output "ami_arm64" {
#   value = data.aws_ami.al2023_arm64.id
# }

# output "ami_x86_64" {
#   value = data.aws_ami.al2_arm64.id
# }

# output "ami" {
#   value = local.ami
# }