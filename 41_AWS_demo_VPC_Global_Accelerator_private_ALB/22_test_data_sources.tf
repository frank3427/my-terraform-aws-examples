# ------ Get latest AMI in this region for AL2 on ARM
data "aws_ami" "test_al2_arm64" {
  region      = var.test_region
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.202*-arm64-gp2"]
  }
  owners = ["amazon"]
}
