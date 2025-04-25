# -- IAM Role to allow API Gateway to send logs to CloudWatch logs
data aws_iam_policy_document demo33_apigw {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data aws_iam_policy demo33_apigw {
  name = "AmazonAPIGatewayPushToCloudWatchLogs"
}

resource aws_iam_role demo33_apigw {
  name                = "demo33_iam_for_apigw"
  assume_role_policy  = data.aws_iam_policy_document.demo33_apigw.json
  managed_policy_arns = [ data.aws_iam_policy.demo33_apigw.arn ]
}

# -- CloudWatch Logs for API gateway
resource aws_cloudwatch_log_group demo33_apigw {
  name              = "/aws/apigateway/demo33"
  retention_in_days = 14
}

# -- REST API
resource aws_api_gateway_rest_api demo33 {
  description = "demo33 API Gateway"
  name = "demo33"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# -- resource path1
resource aws_api_gateway_resource demo33_path1 {
  rest_api_id = aws_api_gateway_rest_api.demo33.id
  parent_id   = aws_api_gateway_rest_api.demo33.root_resource_id
  path_part   = var.apigw_path1
}

resource aws_api_gateway_method demo33_path1 {
  rest_api_id   = aws_api_gateway_rest_api.demo33.id
  resource_id   = aws_api_gateway_resource.demo33_path1.id
  http_method   = "GET"
  authorization = "NONE"
}

resource aws_api_gateway_integration lambda_integration {
  rest_api_id             = aws_api_gateway_rest_api.demo33.id
  resource_id             = aws_api_gateway_resource.demo33_path1.id
  http_method             = aws_api_gateway_method.demo33_path1.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.demo33.invoke_arn
  content_handling        = "CONVERT_TO_TEXT"
}

resource aws_api_gateway_method_response demo33_path1 {
  rest_api_id = aws_api_gateway_rest_api.demo33.id
  resource_id = aws_api_gateway_resource.demo33_path1.id
  http_method = aws_api_gateway_method.demo33_path1.http_method
  status_code = "200"
}

resource aws_api_gateway_integration_response demo33_path1 {
  depends_on = [
    aws_api_gateway_method.demo33_path1,
    aws_api_gateway_integration.lambda_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.demo33.id
  resource_id = aws_api_gateway_resource.demo33_path1.id
  http_method = aws_api_gateway_method.demo33_path1.http_method
  status_code = aws_api_gateway_method_response.demo33_path1.status_code
}

resource aws_api_gateway_deployment demo33_stage1 {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.demo33.id
  stage_name = "demo33-stage1"
}

resource aws_lambda_permission demo33 {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.demo33.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.demo33.execution_arn}/*/GET/*" # ${aws_api_gateway_resource.demo33_path1.path}"
}

output test_curl {
  value = <<EOF
You can test access to API with following command:

curl -i ${aws_api_gateway_deployment.demo33_stage1.invoke_url}${aws_api_gateway_resource.demo33_path1.path}

curl -i ${aws_api_gateway_deployment.demo33_stage1.invoke_url}${aws_api_gateway_resource.demo33_path1.path}?name=christophe

EOF
}

