# -------- Create a IAM role for Lambda function
resource "aws_iam_role" "demo29_for_lambda" {
  name = "demo29_for_lambda"
  tags = { Name = "demo29_for_lambda" }
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

resource "aws_iam_role_policy_attachment" "demo29_ec2roleforssm" {
  role       = aws_iam_role.demo29_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "demo29_managed_instance_core" {
  role       = aws_iam_role.demo29_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}