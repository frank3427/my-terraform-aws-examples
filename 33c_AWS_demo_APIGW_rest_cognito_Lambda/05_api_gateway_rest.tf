# -- IAM Role to allow API Gateway to send logs to CloudWatch logs
data aws_iam_policy_document demo33c_apigw {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data aws_iam_policy demo33c_apigw {
  name = "AmazonAPIGatewayPushToCloudWatchLogs"
}

resource aws_iam_role demo33c_apigw {
  name               = "demo33c_iam_for_apigw"
  assume_role_policy = data.aws_iam_policy_document.demo33c_apigw.json
}

resource aws_iam_role_policy_attachment demo33c_apigw_cloudwatch {
  role       = aws_iam_role.demo33c_apigw.name
  policy_arn = data.aws_iam_policy.demo33c_apigw.arn
}

# -- API Gateway Account (required for CloudWatch logging)
resource aws_api_gateway_account demo33c {
  cloudwatch_role_arn = aws_iam_role.demo33c_apigw.arn
}

# -- CloudWatch Logs for API gateway
resource aws_cloudwatch_log_group demo33c_apigw {
  name              = "/aws/apigateway/${var.project_prefix}"
  retention_in_days = var.cwlogs_retention_in_days
}

# -- REST API
resource aws_api_gateway_rest_api demo33c {
  description = "demo33c API Gateway"
  name = var.project_prefix
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# -- resource path1
resource aws_api_gateway_resource demo33c_path1 {
  rest_api_id = aws_api_gateway_rest_api.demo33c.id
  parent_id   = aws_api_gateway_rest_api.demo33c.root_resource_id
  path_part   = var.apigw_path1
}

resource aws_api_gateway_method proxy {
  rest_api_id      = aws_api_gateway_rest_api.demo33c.id
  resource_id      = aws_api_gateway_resource.demo33c_path1.id
  http_method      = "GET"
  api_key_required = false
  # authorization    = "NONE"
  authorization    = "COGNITO_USER_POOLS"
  authorizer_id    = aws_api_gateway_authorizer.demo33c.id

}

resource aws_api_gateway_integration lambda_integration {
  rest_api_id = aws_api_gateway_rest_api.demo33c.id
  resource_id = aws_api_gateway_resource.demo33c_path1.id
  http_method = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.demo33c.invoke_arn
}

# -- not needed if using AWS_PROXY

# resource aws_api_gateway_method_response proxy {
#   rest_api_id = aws_api_gateway_rest_api.demo33c.id
#   resource_id = aws_api_gateway_resource.demo33c_path1.id
#   http_method = aws_api_gateway_method.proxy.http_method
#   status_code = "200"
# }

# resource aws_api_gateway_integration_response proxy {
#   rest_api_id = aws_api_gateway_rest_api.demo33c.id
#   resource_id = aws_api_gateway_resource.demo33c_path1.id
#   http_method = aws_api_gateway_method.proxy.http_method
#   status_code = aws_api_gateway_method_response.proxy.status_code

#   depends_on = [
#     aws_api_gateway_method.proxy,
#     aws_api_gateway_integration.lambda_integration
#   ]
# }

# -- authorizer for Cognito user pool
resource aws_api_gateway_authorizer demo33c {
  name          = "demo33c_apigw_authorizer"
  rest_api_id   = aws_api_gateway_rest_api.demo33c.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.demo33c.arn]
}

# -- deploy to new stage
resource aws_api_gateway_deployment demo33c {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
  ]
  rest_api_id = aws_api_gateway_rest_api.demo33c.id
}

resource aws_api_gateway_stage demo33c_stage1 {
  deployment_id = aws_api_gateway_deployment.demo33c.id
  rest_api_id   = aws_api_gateway_rest_api.demo33c.id
  stage_name    = "demo33c-stage1"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.demo33c_apigw.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  depends_on = [aws_api_gateway_account.demo33c]
}

resource aws_lambda_permission demo33c {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.demo33c.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.demo33c.execution_arn}/*/*${aws_api_gateway_resource.demo33c_path1.path}"
}