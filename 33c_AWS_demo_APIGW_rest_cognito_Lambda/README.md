# Terraform AWS: API Gateway REST API with Cognito User Pool Authorizer and Lambda Integration

This Terraform project demonstrates how to secure an **AWS API Gateway REST API (v1)** method using an **Amazon Cognito User Pool authorizer**. The API Gateway is integrated with an AWS Lambda function that serves as the backend. Clients must authenticate with the Cognito User Pool and present a valid ID token to access the secured API endpoint.

This project builds upon concepts from `33_AWS_demo_APIGW_rest_Lambda` by adding robust user authentication and authorization.

## Purpose

The primary goal of this project is to illustrate how to:
*   Implement user authentication and authorization for an API Gateway REST API using Amazon Cognito.
*   Create and configure a Cognito User Pool, a User Pool Client, and a sample user.
*   Define a Cognito User Pool authorizer in API Gateway.
*   Secure an API Gateway method by associating it with the Cognito authorizer.
*   Demonstrate the authentication flow where a client obtains an ID token from Cognito and uses it to make authorized API requests.

## Key Components

1.  **AWS Lambda Function (`aws_lambda_function.demo33c`):**
    *   **Runtime:** Python 3.11 (`python3.11`).
    *   **Handler:** `lambda.lambda_handler` (from `lambda.py`).
    *   **Source Code (`lambda.py`):**
        *   A simple Python function that returns a JSON message, potentially including information about the authenticated user if available in the Lambda event context. For this basic demo, it might return a static success message.
        *   The `lambda.py` script is packaged into a zip file by Terraform.
    *   **IAM Role (`aws_iam_role.demo33c_lambda`):**
        *   An IAM role with the `AWSLambdaBasicExecutionRole` policy attached, allowing the Lambda function to write logs to Amazon CloudWatch Logs.
2.  **Amazon Cognito User Pool:**
    *   **User Pool (`aws_cognito_user_pool.demo33c_user_pool`):**
        *   A user directory is created to manage users for the application.
        *   Configured with basic settings (e.g., password policies, attributes).
    *   **User Pool Client (`aws_cognito_user_pool_client.demo33c_user_pool_client`):**
        *   An application client is configured for the user pool. This client is used by applications to interact with the user pool (e.g., for authentication).
        *   Typically configured with settings like `explicit_auth_flows` (e.g., `ADMIN_NO_SRP_AUTH` is enabled, which is useful for the AWS CLI `admin-initiate-auth` command used in testing).
    *   **Sample User (`aws_cognito_user.user1`):**
        *   A sample user (username defined by `var.cognito_user_name`) is created within the user pool.
        *   A **temporary password** is assigned to this user by Terraform (e.g., using `random_password`). For a real user, they would typically set or reset their password upon first login or via an administrator. The temporary password value is outputted by Terraform for testing purposes.
3.  **API Gateway REST API (`aws_api_gateway_rest_api.demo33c_api`):**
    *   **Type:** REST API (v1), Regional endpoint.
    *   **Resource (`aws_api_gateway_resource`):** Creates a resource path (e.g., `/${var.apigw_path1}`).
    *   **Cognito User Pool Authorizer (`aws_api_gateway_authorizer.demo33c_cognito_authorizer`):**
        *   **Type:** `COGNITO_USER_POOLS`.
        *   **`rest_api_id`:** Links it to the `aws_api_gateway_rest_api.demo33c_api`.
        *   **`provider_arns`:** An array containing the ARN of the `aws_cognito_user_pool.demo33c_user_pool`.
        *   **`identity_source`:** `method.request.header.Authorization`. This tells API Gateway to look for the ID token in the `Authorization` header of incoming requests.
    *   **Method (`aws_api_gateway_method.proxy`):**
        *   Defines a `GET` HTTP method for the resource.
        *   **`authorization = "COGNITO_USER_POOLS"`**: Specifies that this method uses a Cognito User Pool authorizer.
        *   **`authorizer_id = aws_api_gateway_authorizer.demo33c_cognito_authorizer.id`**: Links this method to the specific Cognito authorizer created above.
    *   **Integration (`aws_api_gateway_integration`):**
        *   Configured as `AWS_PROXY` to integrate the `GET` method with the Lambda function.
    *   **Deployment and Stage (`aws_api_gateway_deployment`, `aws_api_gateway_stage`):**
        *   Deploys the API to a stage (e.g., `demo33c-stage1`).
4.  **API Gateway Logging & Lambda Permissions:**
    *   Configured similarly to project `33_AWS_demo_APIGW_rest_Lambda`, with an IAM role for API Gateway logging and Lambda permissions for API Gateway invocation. The Lambda permission's `source_arn` is constructed to allow invocation only when authorized by the specific Cognito authorizer on the method.

## Authentication Flow

1.  **Client Authentication:** The client application (or user via AWS CLI for testing) authenticates with the Amazon Cognito User Pool using their credentials (username and password).
2.  **Token Retrieval:** Upon successful authentication, Cognito returns a set of tokens, including an **ID Token**, a JWT (JSON Web Token).
3.  **API Request:** The client makes a request to the secured API Gateway endpoint.
4.  **Authorization Header:** The client includes the retrieved **ID Token** in the `Authorization` header of the HTTP request.
5.  **API Gateway Authorization:** API Gateway receives the request, extracts the ID token from the `Authorization` header, and validates it with the configured Cognito User Pool authorizer.
6.  **Backend Invocation:** If the token is valid and authorized, API Gateway invokes the backend Lambda function. Otherwise, it returns a `401 Unauthorized` error.

## Highlights

*   **Cognito User Pool Authentication:** Demonstrates robust user authentication for APIs using Cognito User Pools.
*   **Granular API Security:** Secures specific API Gateway methods with Cognito authorizers.
*   **Standard JWT Flow:** Leverages JSON Web Tokens (ID Tokens) for passing authentication information.
*   **Client Responsibility:** Clients are responsible for handling the authentication flow with Cognito and including the ID token in requests.

## Key Configuration Variables

*   `aws_region`: The AWS region where all resources will be deployed (e.g., "us-east-1").
*   `apigw_path1`: The path component for the API Gateway resource (e.g., "myresource").
*   `cognito_user_name`: The username for the sample user created in the Cognito User Pool (e.g., "testuser").

## Usage

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Plan Changes:**
    Review the resources that Terraform will create.
    ```bash
    terraform plan
    ```
3.  **Apply Changes:**
    Provision the AWS resources.
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`. Terraform will output:
    *   `apigw_invoke_url_on_path1`: The invocation URL for the API Gateway endpoint.
    *   `cognito_user_pool_id`: The ID of the created Cognito User Pool.
    *   `cognito_user_pool_client_id`: The ID of the User Pool Client.
    *   `cognito_sample_user_username`: The username of the sample user.
    *   `cognito_sample_user_temporary_password`: The temporary password for the sample user. **This is sensitive.**

## Verifying the Setup

After successful deployment:

1.  **Get Outputs:** Note the `apigw_invoke_url_on_path1`, `cognito_user_pool_id`, `cognito_user_pool_client_id`, `cognito_sample_user_username`, and `cognito_sample_user_temporary_password` from `terraform output`.

2.  **Test WITHOUT Authorization Token (Expect 401 Unauthorized):**
    Use `curl` to make a request to the invocation URL without any `Authorization` header.
    ```bash
    curl -v "<apigw_invoke_url_on_path1_output_value>"
    # Example: curl -v https://abcdef123.execute-api.us-east-1.amazonaws.com/demo33c-stage1/myresource
    ```
    *   **Expected Output:** You should receive an HTTP `401 Unauthorized` response. The body might include `{"message":"Unauthorized"}`.

3.  **Obtain Cognito ID Token for the Sample User:**
    Use the AWS CLI to authenticate the sample user and get an ID token. You'll need the outputs from step 1.
    ```bash
    # Replace placeholders with actual values from Terraform output
    USER_POOL_ID="<cognito_user_pool_id_output_value>"
    CLIENT_ID="<cognito_user_pool_client_id_output_value>"
    USERNAME="<cognito_sample_user_username_output_value>"
    PASSWORD="<cognito_sample_user_temporary_password_output_value>"
    REGION="<aws_region_output_value>" # e.g., us-east-1

    # Initiate authentication. For a user created with a temporary password,
    # Cognito might require a NEW_PASSWORD_REQUIRED challenge first.
    # This command attempts to directly authenticate. If it fails with NEW_PASSWORD_REQUIRED,
    # you'd typically handle that challenge (e.g., aws cognito-idp admin-set-user-password or respond-to-auth-challenge).
    # For simplicity in this test, we assume direct auth or that the user password was finalized.
    # If the temporary password needs to be changed first, the flow is more complex for CLI.
    # A simpler test for admin-initiate-auth might bypass this if explicit_auth_flows allows ADMIN_USER_PASSWORD_AUTH.

    # Using admin-initiate-auth (requires ADMIN_NO_SRP_AUTH or ADMIN_USER_PASSWORD_AUTH enabled on client)
    # This is often easier for testing with temporary passwords set by an admin/script.
    AUTH_RESPONSE=$(aws cognito-idp admin-initiate-auth \
        --user-pool-id $USER_POOL_ID \
        --client-id $CLIENT_ID \
        --auth-flow ADMIN_USER_PASSWORD_AUTH \
        --auth-parameters USERNAME=$USERNAME,PASSWORD=$PASSWORD \
        --region $REGION \
        --query "AuthenticationResult.IdToken" --output text)

    if [ -z "$AUTH_RESPONSE" ]; then
        echo "Failed to get ID token. Check user password status or auth flow."
        exit 1
    fi
    ID_TOKEN=$AUTH_RESPONSE
    echo "ID Token: $ID_TOKEN"
    ```
    **Note:** If `ADMIN_USER_PASSWORD_AUTH` is not enabled in `explicit_auth_flows` for the user pool client, this CLI command will fail. The default setup in the provided Terraform code enables `ADMIN_NO_SRP_AUTH`, `USER_SRP_AUTH`, and `REFRESH_TOKEN_AUTH`. You might need to adjust the `explicit_auth_flows` in `aws_cognito_user_pool_client.demo33c_user_pool_client` to include `ADMIN_USER_PASSWORD_AUTH` for this CLI command to work easily, or use a different authentication flow (e.g., via Amplify libraries or other Cognito SDK methods). Alternatively, after first login with a temporary password, a user is typically forced to set a new password.

4.  **Test WITH Authorization Token (Expect 200 OK):**
    Make a request including the obtained ID Token in the `Authorization` header.
    ```bash
    curl -v --header "Authorization: $ID_TOKEN" "<apigw_invoke_url_on_path1_output_value>"
    ```
    *   **Expected Output:** You should receive an HTTP `200 OK` response, and the body should be the JSON from the Lambda function (e.g., `{"message": "hello world"}`).

5.  **Check API Gateway Execution Logs (if enabled in Stage settings):**
    *   Monitor CloudWatch Logs for the API Gateway for details on authorizer processing and request handling.

6.  **Check Lambda Execution Logs:**
    *   Monitor CloudWatch Logs for the Lambda function (`/aws/lambda/demo33c_lambda_py`). You should see invocation logs for successful, authorized requests. The `event` object logged by Lambda will contain details about the authenticated Cognito user in the `requestContext.authorizer.claims` section.

This testing procedure validates that the API Gateway is correctly secured using the Cognito User Pool authorizer.
