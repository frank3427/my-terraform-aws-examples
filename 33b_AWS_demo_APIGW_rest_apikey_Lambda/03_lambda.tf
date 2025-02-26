data aws_iam_policy_document demo33b_lambda {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource aws_iam_role demo33b_lambda {
  name                = "demo33b_iam_for_lambda"
  assume_role_policy  = data.aws_iam_policy_document.demo33b_lambda.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

data archive_file demo33b {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda_function_payload.zip"
}

resource aws_lambda_function demo33b {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_function_payload.zip"
  function_name = "demo33b"
  role          = aws_iam_role.demo33b_lambda.arn
  handler       = "lambda.lambda_handler"

  source_code_hash = data.archive_file.demo33b.output_base64sha256

  runtime = "python3.11"

  environment {
    variables = {
      foo = "bar"
    }
  }
}