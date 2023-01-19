data aws_ami win2022 {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-2022*"]
  }

   owners = ["amazon"]
}

# -------------------------------------------------------------------------------
# |                               DescribeImages                                |
# +------------------------+----------------------------------------------------+
# |  ami-087bd7b534bcbfa5b |  Windows_Server-2022-English-Full-Base-2022.10.27  |
# |  ami-0e141cfb786615299 |  Windows_Server-2022-English-Full-Base-2022.09.14  |
# |  ami-0a20b6d46b59a5cd5 |  Windows_Server-2022-English-Full-Base-2022.10.12  |
# |  ami-068c15df4f4a228a2 |  Windows_Server-2022-English-Full-Base-2022.07.13  |
# |  ami-0d01d709c8dd49cb1 |  Windows_Server-2022-English-Full-Base-2022.08.10  |
# +------------------------+----------------------------------------------------+