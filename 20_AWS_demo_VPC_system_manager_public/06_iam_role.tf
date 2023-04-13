# -------- Create a IAM role and IAM instance profile to allow EC2 instances to communicate with System Manager
resource aws_iam_role demo20_ssm {
    name                = "demo20_ssm_for_ec2"
    tags                = { Name = "demo20_ssm_for_ec2" }
    managed_policy_arns = [ "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
                            "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" ]
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

resource aws_iam_instance_profile demo20_ssm {
  name = "demo20_ssm_for_ec2_instprof"
  role = aws_iam_role.demo20_ssm.name
}