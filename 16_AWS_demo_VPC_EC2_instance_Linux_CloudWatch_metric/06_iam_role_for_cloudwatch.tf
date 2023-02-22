# -------- Create a IAM role and IAM instance profile to allow EC2 instance to send custom metrics to CloudWatch 
resource aws_iam_role demo16_cloudwatch {
    name                = "demo16_cw_for_ec2"
    tags                = { Name = "demo16_cw_for_ec2" }
    managed_policy_arns = [ "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy" ]
    assume_role_policy  = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Sid    = ""
            Principal = {
                Service = "ec2.amazonaws.com"
            }
        },
        ]
    })

}

resource aws_iam_instance_profile demo16_cloudwatch {
  name = "demo16_cw_for_ec2_instprof"
  role = aws_iam_role.demo16_cloudwatch.name
}