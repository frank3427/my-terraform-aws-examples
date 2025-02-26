# -- Cognito user pool
resource aws_cognito_user_pool demo33c {
  name = "demo33c-pool"
}

resource aws_cognito_user_pool_client demo33c {
  name                         = "demo33c-client-apigw"
  allowed_oauth_flows_user_pool_client = true
  generate_secret              = false
  allowed_oauth_scopes         = ["aws.cognito.signin.user.admin","email", "openid", "profile"]
  allowed_oauth_flows          = ["implicit", "code"]
  explicit_auth_flows          = ["ADMIN_NO_SRP_AUTH", "USER_PASSWORD_AUTH"]
  supported_identity_providers = ["COGNITO"]
  user_pool_id                 =  aws_cognito_user_pool.demo33c.id
  callback_urls                = ["https://example.com"]
  logout_urls                  = ["https://example.com"]
}

# -- genereate a random password for Cognito user
resource random_string demo33c_user1_password {
  # must contains at least 2 upper case letters, 2 lower case letters, 2 numbers and 2 special characters
  length      = 12
  upper       = true
  min_upper   = 2
  lower       = true
  min_lower   = 2
  numeric     = true
  min_numeric = 2
  special     = true
  min_special = 2
  override_special = "#-_"   # use only special characters in this list
}

locals {
    user_password = random_string.demo33c_user1_password.result
} 

# -- Cognito user
resource aws_cognito_user user1 {
  user_pool_id = aws_cognito_user_pool.demo33c.id
  username     = var.cognito_user_name
  password     = local.user_password
}