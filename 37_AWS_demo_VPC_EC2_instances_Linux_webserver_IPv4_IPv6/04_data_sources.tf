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

locals {
  ami_al_arm64  = data.aws_ami.al2023_arm64.id    
  ami_al_x86_64 = data.aws_ami.al2023_x86_64.id   
  ami           = (var.arch  == "arm64")  ? local.ami_al_arm64 : local.ami_al_x86_64
}