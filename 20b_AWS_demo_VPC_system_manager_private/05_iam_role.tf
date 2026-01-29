# -------- Create a IAM role and IAM instance profile to allow EC2 instances to communicate with System Manager
# Note: if logging to S3 is configured in region settings, then add S3 permissions.
resource aws_iam_role demo20b_ssm {
    name               = "demo20b_ssm_for_ec2"
    tags               = { Name = "demo20b_ssm_for_ec2" }
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

resource aws_iam_instance_profile demo20b_ssm {
  name = "demo20b_ssm_for_ec2_instprof"
  role = aws_iam_role.demo20b_ssm.name
}

resource aws_iam_role_policy_attachment demo20b_ssm_managed_instance {
  role       = aws_iam_role.demo20b_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource aws_iam_role_policy demo20b_ssm_s3 {
  count = local.session_manager_s3_bucket == "" ? 0 : 1
  name = "demo20b_ssm_s3_policy"
  role = aws_iam_role.demo20b_ssm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetEncryptionConfiguration",
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*" 
        # [
        #   "arn:aws:s3:::${local.session_manager_s3_bucket}",
        #   "arn:aws:s3:::${local.session_manager_s3_bucket}/*"
        # ]
      },
    ]
  })
}

resource aws_iam_role_policy demo20b_ssm_cwlogs {
  count = local.session_manager_cw_log_grp == "" ? 0 : 1
  name = "demo20b_ssm_cwlogs_policy"
  role = aws_iam_role.demo20b_ssm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
          "Effect": "Allow",
          "Action": [
              "ssmmessages:CreateControlChannel",
              "ssmmessages:CreateDataChannel",
              "ssmmessages:OpenControlChannel",
              "ssmmessages:OpenDataChannel",
              "ssm:UpdateInstanceInformation"
          ],
          "Resource": "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]
        Resource = "*"
        # [
        #   "arn:aws:logs:${var.aws_region}:*:log-group:${local.session_manager_cw_log_grp}:*"
        # ]
      },
    ]
  })
}