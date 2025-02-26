resource aws_lambda_permission demo32 {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.demo32.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_apigatewayv2_api.demo32.execution_arn}/*/*/${var.apigw_path1}"
}

resource aws_apigatewayv2_api demo32 {
  name          = "demo32-http-api"
  protocol_type = "HTTP"
}

resource aws_apigatewayv2_route demo32 {
  api_id    = aws_apigatewayv2_api.demo32.id
  route_key = "ANY /${var.apigw_path1}"

  target = "integrations/${aws_apigatewayv2_integration.demo32.id}"
}

resource aws_cloudwatch_log_group demo32 {
  name              = "/aws/apigateway/demo32"
  retention_in_days = 14
}

resource aws_apigatewayv2_stage demo32 {
  api_id      = aws_apigatewayv2_api.demo32.id
  name        = "$default"
  auto_deploy = true
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.demo32.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }
}

resource aws_apigatewayv2_integration demo32 {
  api_id           = aws_apigatewayv2_api.demo32.id
  integration_type = "AWS_PROXY"
  description               = "demo32 Lambda example"
  integration_method        = "POST"
  integration_uri           = aws_lambda_function.demo32.invoke_arn
  passthrough_behavior      = "WHEN_NO_MATCH"
  payload_format_version    = "2.0"
}

output test_curl {
  value = <<EOF
You can test access to API with following command:

curl -i ${aws_apigatewayv2_stage.demo32.invoke_url}${var.apigw_path1}

EOF
}