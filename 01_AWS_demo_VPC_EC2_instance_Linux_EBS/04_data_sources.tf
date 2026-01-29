# ---- AMI for X64 architecture
data aws_ami x64 {
  most_recent = true

  filter {
    name   = "name"
    values = [ local.os_to_filter_x64[var.linux_os_version] ]
  }
   owners = ["amazon"]
}

# ---- AMI for ARM64 architecture
data aws_ami arm64 {
  most_recent = true

  filter {
    name   = "name"
    values = [ local.os_to_filter_arm64[var.linux_os_version] ]
  }
   owners = ["amazon"]
}

# ---- Get the right AMI
locals {
  os_to_filter_x64 = {
    "al2023": "al2023-ami-2023*x86_64",
    "al2": "amzn2-ami-kernel-5.10-hvm-2.0.202*x86_64-gp2",
    "ubuntu22": "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-202*",
    "ubuntu24": "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*",
    "sles15": "suse-sles-15-sp6-v202*hvm-ssd-x86_64",
    "rhel9": "RHEL-9*_HVM-202*x86_64*"
  }
  os_to_filter_arm64 = {
    "al2023": "al2023-ami-2023*arm64",
    "al2": "amzn2-ami-kernel-5.10-hvm-2.0.202*arm64-gp2",
    "ubuntu22": "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-202*",
    "ubuntu24": "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*",
    "sles15": "suse-sles-15-sp6-v202*hvm-ssd-x86_64",
    "rhel9": "RHEL-9*_HVM-202*arm64*"
  }
  ami = (var.arch  == "arm64")  ? data.aws_ami.arm64.id : data.aws_ami.x64.id
}

output "ami" {
  value = local.ami
}