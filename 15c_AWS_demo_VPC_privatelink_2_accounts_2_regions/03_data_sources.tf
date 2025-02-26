data aws_ami acct1_al2023_arm64 {
  provider    = aws.acct1
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*arm64"]
  }
   owners = ["amazon"]
}

data aws_ami acct2_al2023_arm64 {
  provider    = aws.acct2
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*arm64"]
  }
   owners = ["amazon"]
}

