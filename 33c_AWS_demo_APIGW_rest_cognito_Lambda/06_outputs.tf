output test_curl {
  value = <<EOF
You can test access to API with following command:

curl -i ${aws_api_gateway_stage.demo33c_stage1.invoke_url}${aws_api_gateway_resource.demo33c_path1.path}

This command should fail with error 401 (Unauthorized) as Cognito is enabled.

You can generate an access token for Cognito user with following command:

aws cognito-idp admin-initiate-auth \
    --region ${var.aws_region} \
    --client-id ${aws_cognito_user_pool_client.demo33c.id} \
    --user-pool-id ${aws_cognito_user_pool.demo33c.id} \
    --auth-flow ADMIN_NO_SRP_AUTH \
    --auth-parameters USERNAME=${var.cognito_user_name},PASSWORD=${local.user_password}

You can now use the IdToken seen in the response to access API with following commands:

TOKEN=<value of IdToken>
curl -i \
    -H "Authorization: Bearer $TOKEN" \
    ${aws_api_gateway_stage.demo33c_stage1.invoke_url}${aws_api_gateway_resource.demo33c_path1.path}

EOF
}

