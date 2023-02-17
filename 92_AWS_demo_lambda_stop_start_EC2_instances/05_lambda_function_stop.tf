resource aws_lambda_function demo92_stop {
    filename      = "lambda_function_stop.zip"
    function_name = "demo92_stop_ec2"
    role          = aws_iam_role.demo92.arn
    handler       = "lambda_function_stop.lambda_handler"
    description   = "Stop some EC2 instances"

    source_code_hash = filebase64sha256("lambda_function_stop.zip")

    runtime = "python3.8"

    environment {
        variables = {
            REGION       = "eu-west-1",
            INSTANCE_IDS = "i-04f9b09d4633b8efe,i-023d40b01948e7a2a"
        }
    }
}