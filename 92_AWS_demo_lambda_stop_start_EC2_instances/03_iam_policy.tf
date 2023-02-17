resource aws_iam_policy demo92 {
    name        = "demo92_start_stop_ec2"
    path        = "/"
    description = "IAM policy used by IAM role in Lambda function to stop/start EC2 instances"

    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
            },
            {
            "Effect": "Allow",
            "Action": [
                "ec2:Start*",
                "ec2:Stop*"
            ],
            "Resource": "*"
            }
        ]
    })
}