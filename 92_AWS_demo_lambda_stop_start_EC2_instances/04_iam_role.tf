resource aws_iam_role demo92 {
    name = "demo92_start_stop_ec2"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Sid    = ""
            Principal = {
                Service = "lambda.amazonaws.com"
            }
        },
        ]
    })
}

resource aws_iam_role_policy_attachment demo92 {
  role       = aws_iam_role.demo92.name
  policy_arn = aws_iam_policy.demo92.arn
}