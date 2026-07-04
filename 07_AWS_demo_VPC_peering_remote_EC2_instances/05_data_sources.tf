# ---- AMI for AL2023 in region 1
data "aws_ami" "al2023_r1" {
  provider    = aws.r1
  most_recent = true

  filter {
    name   = "name"
    values = [local.ami_filter]
  }
  owners = ["amazon"]
}

# ---- AMI for AL2023 in region 2
data "aws_ami" "al2023_r2" {
  provider    = aws.r2
  most_recent = true

  filter {
    name   = "name"
    values = [local.ami_filter]
  }
  owners = ["amazon"]
}

locals {
  ami_filter = (var.arch == "arm64") ? "al2023-ami-2023*arm64" : "al2023-ami-2023*x86_64"
}
