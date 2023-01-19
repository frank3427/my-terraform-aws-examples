# ------ Display the complete ssh command needed to connect to the instance
locals {
  username   = "ec2-user"
}

output Instructions {
  value = <<EOF


---- You can SSH directly to the Linux instance with Oracle Instance Client by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo10_al2.public_ip}

---- Once connected, you can connect to the Oracle database using sqlplus with following command
./sqlplus.sh
Password is ${random_string.demo10-db-passwd.result}

EOF
}