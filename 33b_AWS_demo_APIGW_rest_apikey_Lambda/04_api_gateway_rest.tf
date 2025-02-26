# -- IAM Role to allow API Gateway to send logs to CloudWatch logs
data aws_iam_policy_document demo33b_apigw {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data aws_iam_policy demo33b_apigw {
  name = "AmazonAPIGatewayPushToCloudWatchLogs"
}

resource aws_iam_role demo33b_apigw {
  name                = "demo33b_iam_for_apigw"
  assume_role_policy  = data.aws_iam_policy_document.demo33b_apigw.json
  managed_policy_arns = [ data.aws_iam_policy.demo33b_apigw.arn ]
}

# -- CloudWatch Logs for API gateway
resource aws_cloudwatch_log_group demo33b_apigw {
  name              = "/aws/apigateway/demo33b"
  retention_in_days = 14
}

# -- REST API
resource aws_api_gateway_rest_api demo33b {
  description = "demo33b API Gateway"
  name        = "demo33b"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# -- resource path1
resource aws_api_gateway_resource demo33b_path1 {
  rest_api_id = aws_api_gateway_rest_api.demo33b.id
  parent_id   = aws_api_gateway_rest_api.demo33b.root_resource_id
  path_part   = var.apigw_path1
}

resource aws_api_gateway_method proxy {
  rest_api_id      = aws_api_gateway_rest_api.demo33b.id
  resource_id      = aws_api_gateway_resource.demo33b_path1.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

resource aws_api_gateway_integration lambda_integration {
  rest_api_id             = aws_api_gateway_rest_api.demo33b.id
  resource_id             = aws_api_gateway_resource.demo33b_path1.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.demo33b.invoke_arn
}

resource aws_api_gateway_method_response proxy {
  rest_api_id = aws_api_gateway_rest_api.demo33b.id
  resource_id = aws_api_gateway_resource.demo33b_path1.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"
}

resource aws_api_gateway_integration_response proxy {
  rest_api_id = aws_api_gateway_rest_api.demo33b.id
  resource_id = aws_api_gateway_resource.demo33b_path1.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.lambda_integration
  ]
}

resource aws_api_gateway_deployment demo33b {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
  ]
  rest_api_id = aws_api_gateway_rest_api.demo33b.id
  # stage_name = "demo33b-stage1"
}

resource aws_api_gateway_stage demo33b_stage1 {
  deployment_id = aws_api_gateway_deployment.demo33b.id
  rest_api_id   = aws_api_gateway_rest_api.demo33b.id
  stage_name    = "demo33b-stage1"
}

resource aws_lambda_permission demo33b {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.demo33b.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.demo33b.execution_arn}/*/*${aws_api_gateway_resource.demo33b_path1.path}"
}

resource aws_api_gateway_api_key demo33b_apikey1 {
  name = "demo33b_apikey1"
}

resource aws_api_gateway_usage_plan demo33b {
  name         = "demo33b_apikey"
  description  = "usage plan for API key"

  api_stages {
    api_id = aws_api_gateway_rest_api.demo33b.id
    stage  = aws_api_gateway_stage.demo33b_stage1.stage_name
  }

  # quota_settings {
  #   limit  = 20
  #   offset = 2
  #   period = "WEEK"
  # }

  # throttle_settings {
  #   burst_limit = 5
  #   rate_limit  = 10
  # }
}

resource aws_api_gateway_usage_plan_key demo33b {
  key_id        = aws_api_gateway_api_key.demo33b_apikey1.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.demo33b.id
}

output test_curl {
  value = <<EOF
You can test access to API with following command:

Without API key:
curl -i ${aws_api_gateway_stage.demo33b_stage1.invoke_url}${aws_api_gateway_resource.demo33b_path1.path}

With API key:
curl -i -H "x-api-key: ${nonsensitive(aws_api_gateway_api_key.demo33b_apikey1.value)}" \
    ${aws_api_gateway_stage.demo33b_stage1.invoke_url}${aws_api_gateway_resource.demo33b_path1.path}

EOF
}

