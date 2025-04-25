# ------ SSH config file
resource local_file sshconfig {
  content = templatefile("templates/sshcfg.template", {
    username             = "ec2-user",
    bastion_public_ip    = aws_eip.demo20b_bastion.public_ip,
    instances            = aws_instance.demo20b,
    ssh_private_key_file = var.private_sshkey_path
  })
  filename = "sshcfg"
  file_permission = "0600"
}

# ------ Display the complete ssh command needed to connect to the instance
output Bastion {
  value = <<EOF


---- You can SSH to the EC2 instances with following commands:
ssh -F sshcfg demo20b-bastion
${join("\n",[for instance in aws_instance.demo20b: "ssh -F sshcfg ${instance.tags_all.Name}"])}

---- You should be able to connect to all instances using Session Manager in AWS Console

EOF
}