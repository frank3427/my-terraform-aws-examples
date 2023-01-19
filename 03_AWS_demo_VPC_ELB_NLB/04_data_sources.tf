# data aws_ami ubuntu_2204_arm64 {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-2022*"]
#   }
#    owners = ["amazon"]
# }

data aws_ami al2_arm64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.20221004.0-arm64-gp2"]
  }
   owners = ["amazon"]
}
