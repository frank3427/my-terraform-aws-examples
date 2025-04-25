data aws_iam_policy_document demo32 {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource aws_iam_role demo32 {
  name               = "demo32_iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.demo32.json
}

data archive_file demo32 {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda_function_payload.zip"
}

resource aws_lambda_function demo32 {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_function_payload.zip"
  function_name = "demo32"
  role          = aws_iam_role.demo32.arn
  handler       = "lambda.lambda_handler"

  source_code_hash = data.archive_file.demo32.output_base64sha256

  runtime = "python3.11"

  environment {
    variables = {
      foo = "bar"
    }
  }
}