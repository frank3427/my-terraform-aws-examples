# ------ Create an IAM role to allow S3 operations from an EC2 instance 
resource aws_iam_instance_profile demo05 {
  name = "demo05_instance_profile"
  role = aws_iam_role.demo05.name
}

resource aws_iam_role demo05 {
  name = "demo05_role"

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

resource aws_iam_role_policy demo_s3 {
  name = "demo05_s3_policy"
  role = aws_iam_role.demo05.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
            ],
            "Resource": "*"
        }
    ]
  })
}