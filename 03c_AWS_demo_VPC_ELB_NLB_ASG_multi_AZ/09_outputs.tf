# ------ Display connection instructions
output CONNECTIONS {
  value = <<EOF

  Wait a few minutes so that post-provisioning scripts can run on the compute instances
  Then you can use instructions below to connect

  1) ---- Session Manager connection to web server instances using AWS CLI
          (You can also use Session Manager from the AWS Console)
     Use AWS CLI to get instance IDs:
     export AWS_REGION="${var.aws_region}"
     aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=demo03c-websrv-asg" --query "Reservations[].Instances[].InstanceId" --output table
     
     Then connect using Session Manager:
     aws ssm start-session --target <INSTANCE-ID>

  2) ---- HTTP connection to public load balancer
     Open the following URL in your Web browser:
     http://${aws_lb.demo03c_nlb.dns_name}

EOF

}

#dig google.com +short
