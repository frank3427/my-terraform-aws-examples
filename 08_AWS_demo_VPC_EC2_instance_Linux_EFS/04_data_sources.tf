data aws_ami al2023_arm64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*arm64"]
  }
   owners = ["amazon"]
}