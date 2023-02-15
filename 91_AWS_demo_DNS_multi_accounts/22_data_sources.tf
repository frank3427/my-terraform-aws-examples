# ---- AMI for Amazon Linux 2 on X86_64 architecture
data aws_ami al2_x86_64_acct1 {
  provider    = aws.acct1
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.202*x86_64-gp2"]
  }
   owners = ["amazon"]
}

# ---- AMI for Amazon Linux 2 on X86_64 architecture
data aws_ami al2_x86_64_acct2 {
  provider    = aws.acct2
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.202*x86_64-gp2"]
  }
   owners = ["amazon"]
}

# ---- get AWS account IDs for acct1 and acct2 accounts
data aws_caller_identity acct1 {
  provider = aws.acct1
}

data aws_caller_identity acct2 {
  provider = aws.acct2
}