data aws_iam_policy_document demo33c_lambda {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource aws_iam_role demo33c_lambda {
  name               = "demo33c_iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.demo33c_lambda.json
}

resource aws_iam_role_policy_attachment demo33c_lambda_basic_execution {
  role       = aws_iam_role.demo33c_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data archive_file demo33c {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda_function_payload.zip"
}

# -- CloudWatch Logs for Lambda function
resource aws_cloudwatch_log_group demo33c_lambda {
  name              = "/aws/lambda/${var.project_prefix}"
  retention_in_days = var.cwlogs_retention_in_days
}

# -- Lambda function
resource aws_lambda_function demo33c {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_function_payload.zip"
  function_name = var.project_prefix
  role          = aws_iam_role.demo33c_lambda.arn
  handler       = "lambda.lambda_handler"

  source_code_hash = data.archive_file.demo33c.output_base64sha256

  runtime = var.lambda_runtime

  # environment {
  #   variables = {
  #     foo = "bar"
  #   }
  # }
}