# see https://docs.aws.amazon.com/pcs/latest/userguide/security-instance-profiles.html

resource aws_iam_instance_profile demo45a {
  name = "AWSPCS_demo45a_instance_profile"
  role = aws_iam_role.demo45a.name
}

resource aws_iam_role demo45a {
  name = "AWSPCS_demo45a_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource aws_iam_role_policy demo45a {
  name = "demo45a_policy"
  role = aws_iam_role.demo45a.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "pcs:RegisterComputeNodeGroupInstance"
            ],
            "Resource": "*"
        }
    ]
  })
}