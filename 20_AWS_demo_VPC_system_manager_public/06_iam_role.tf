# -------- Create a IAM role and IAM instance profile to allow EC2 instances to communicate with System Manager
resource "aws_iam_role" "demo20_ssm" {
  name = "demo20_ssm_for_ec2"
  tags = { Name = "demo20_ssm_for_ec2" }
  assume_role_policy = jsonencode({
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

resource "aws_iam_role_policy_attachment" "demo20_ssm_ec2roleforssm" {
  role       = aws_iam_role.demo20_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "demo20_ssm_managed_instance_core" {
  role       = aws_iam_role.demo20_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "demo20_ssm" {
  name = "demo20_ssm_for_ec2_instprof"
  role = aws_iam_role.demo20_ssm.name
}