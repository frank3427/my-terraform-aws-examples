# ------ Create IAM role and instance profile for Session Manager
resource aws_iam_role demo03c_ssm {
  name = "demo03c_ssm_for_ec2"
  tags = { Name = "demo03c_ssm_for_ec2" }
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource aws_iam_instance_profile demo03c_ssm {
  name = "demo03c_ssm_for_ec2_instprof"
  role = aws_iam_role.demo03c_ssm.name
}

resource aws_iam_role_policy_attachment demo03c_ssm_managed_instance {
  role       = aws_iam_role.demo03c_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ------ Additional permissions for Session Manager logging
resource aws_iam_role_policy demo03c_ssm_logging {
  name = "demo03c_ssm_logging_policy"
  role = aws_iam_role.demo03c_ssm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}