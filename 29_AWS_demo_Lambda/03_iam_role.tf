# -------- Create a IAM role and IAM instance profile to allow EC2 instances to communicate with System Manager
resource aws_iam_role demo29_for_lambda {
    name                = "demo29_for_lambda"
    tags                = { Name = "demo29_for_lambda" }
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
                Service = "lambda.amazonaws.com"
            }
        },
        ]
    })

}