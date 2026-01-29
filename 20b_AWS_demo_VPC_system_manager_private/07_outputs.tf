output Connection {
  value = <<EOF

For security reasons, you cannot to the EC2 instances using SSH but you can do it using Session Manager:
- either using AWS Console
- or using AWS CLI command (requires AWS CLI and Session Manager Plugin):
      aws ssm start-session --target ${aws_instance.demo20b[0].id} --region ${var.aws_region}
      aws ssm start-session --target ${aws_instance.demo20b[1].id} --region ${var.aws_region}

EOF
}