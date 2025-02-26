data archive_file demo29_lambda {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda_function_payload.zip"
}

resource aws_lambda_function demo29 {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_function_payload.zip"
  function_name = "demo29_lambda"
  description   = "demo29 provisioned by Terraform"
  role          = aws_iam_role.demo29_for_lambda.arn
  handler       = "lambda.lambda_handler"

  source_code_hash = data.archive_file.demo29_lambda.output_base64sha256

  runtime = "python3.11"

  environment {
    variables = {
      foo = "bar"
    }
  }
}