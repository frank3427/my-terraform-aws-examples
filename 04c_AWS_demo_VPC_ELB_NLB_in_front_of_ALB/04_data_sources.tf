# ------ Get list of available AZs in the region specified in provider
data "aws_availability_zones" "available" {
  state = "available"
}

# ------ Get latest Amazon Linux 2 AMI for ARM64
data "aws_ami" "al2023_arm64" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-202*arm64"]
  }
  owners = ["amazon"]
}
