# Terraform AWS: API Gateway REST API (v1) with Lambda Integration

This Terraform project demonstrates how to provision a serverless application using an **AWS Lambda function** integrated with an **AWS API Gateway REST API (v1)**. This setup allows you to expose your Lambda function as an HTTP endpoint, capable of processing query string parameters.

## Purpose

The primary goal of this project is to illustrate the deployment of a Lambda-backed API using the traditional API Gateway REST API (v1). This includes:
*   Creating a Python Lambda function that can parse and use query string parameters.
*   Setting up an API Gateway REST API with specific resources, methods, and integrations.
*   Configuring Lambda Proxy integration (`AWS_PROXY`) for seamless data flow between API Gateway and Lambda.
*   Deploying the API to a stage.
*   Ensuring proper IAM permissions for Lambda execution and API Gateway logging.

While API Gateway HTTP APIs (v2) are often preferred for simpler, lower-cost, and lower-latency use cases, REST APIs (v1) provide more features and control over the request/response lifecycle, integrations, and authorizers.

## Key Components

1.  **AWS Lambda Function (`aws_lambda_function.demo33`):**
    *   **Runtime:** Python 3.11 (`python3.11`).
    *   **Handler:** `lambda.lambda_handler` (from `lambda.py`).
    *   **Source Code (`lambda.py`):**
        *   A Python function designed to:
            1.  Extract an optional query string parameter named `name` from the event object passed by API Gateway.
            2.  Return a personalized JSON greeting: `{"message": "hello world {name}"}` if `name` is provided, or a default `{"message": "hello world"}` if `name` is not.
        *   The `lambda.py` script is packaged into a zip file (`lambda_function_payload.zip`) by Terraform using `data "archive_file"`.
    *   **IAM Role (`aws_iam_role.demo33_lambda`):**
        *   An IAM role is created for the Lambda function.
        *   **Policy Attachment:** The AWS managed policy `AWSLambdaBasicExecutionRole` is attached. This grants the Lambda function essential permissions to write logs to Amazon CloudWatch Logs, which is crucial for monitoring and debugging.
2.  **API Gateway REST API (`aws_api_gateway_rest_api.demo33`):**
    *   **Type:** This is a REST API (v1), configured as a `REGIONAL` endpoint.
    *   **Resource (`aws_api_gateway_resource.demo33_path1`):**
        *   Creates a resource path under the API's root (e.g., `/${var.apigw_path1}`, which could be `/greet`).
    *   **Method (`aws_api_gateway_method.demo33_get_method_on_path1`):**
        *   Defines a `GET` HTTP method for the created resource path.
        *   `authorization = "NONE"`: Specifies that this method does not require any authorization.
    *   **Integration (`aws_api_gateway_integration.demo33_lambda_integration_for_get_on_path1`):**
        *   **Type:** `AWS_PROXY`. This is the Lambda Proxy integration type, where API Gateway passes the raw request directly to the Lambda function. The Lambda function's response (which must be in a specific JSON format) is then mapped back by API Gateway to an HTTP response.
        *   Connects the `GET` method to the `aws_lambda_function.demo33`.
    *   **Method Response & Integration Response:**
        *   `aws_api_gateway_method_response`: Defines the HTTP 200 OK response for the `GET` method.
        *   `aws_api_gateway_integration_response`: Configures how the Lambda's response is mapped to the HTTP 200 method response.
    *   **Deployment (`aws_api_gateway_deployment.demo33_deployment`):**
        *   Deploys the API configuration to make it callable. This resource depends on the method and integration resources to ensure changes are deployed.
    *   **Stage (`aws_api_gateway_stage.demo33_stage1`):**
        *   Creates a stage (e.g., `demo33-stage1`) for the deployment. The API is invoked via a URL that includes the stage name.
3.  **API Gateway Logging:**
    *   **IAM Role for API Gateway Logging (`aws_iam_role.demo33_apigw_cloudwatch_role`):**
        *   An IAM role is created that API Gateway can assume.
        *   The AWS managed policy `AmazonAPIGatewayPushToCloudWatchLogs` is attached, allowing API Gateway to write execution logs and access logs to CloudWatch.
    *   **CloudWatch Log Group (`aws_cloudwatch_log_group.demo33_apigw_logs`):**
        *   A log group (e.g., `/aws/apigateway/demo33_rest_api_access_logs`) is created.
        *   **Note:** For API Gateway execution and/or access logs to be written to this group, logging settings must be configured within the **Stage settings** of the `aws_api_gateway_stage` resource (e.g., setting `access_log_settings` or `xray_tracing_enabled`). This project creates the log group and role, but the explicit enabling of logging in the stage settings might not be fully detailed in the provided snippets and would be required for logs to appear.
4.  **Lambda Permission (`aws_lambda_permission.demo33_apigw_can_invoke_lambda`):**
    *   Grants the API Gateway service permission to invoke the `aws_lambda_function.demo33` for the specific `GET` method on the defined resource path. The `source_arn` in this permission is constructed to be specific to the method being authorized.

## Highlights

*   **API Gateway REST API (v1) Structure:** Demonstrates the more granular setup of REST APIs, involving explicit definition of resources, methods, integrations, and deployments.
*   **Query String Parameter Processing:** The Lambda function is designed to read and use query string parameters (e.g., `?name=value`) passed through the API Gateway.
*   **Correct Lambda Logging IAM:** The Lambda function's IAM role includes `AWSLambdaBasicExecutionRole`, ensuring it can write execution logs to CloudWatch.
*   **Lambda Proxy Integration:** Utilizes the `AWS_PROXY` integration type for straightforward request and response handling between API Gateway and Lambda.

## Key Configuration Variables

*   `aws_region`: The AWS region where all resources will be deployed (e.g., "us-east-1").
*   `apigw_path1`: The path component for the API Gateway resource (e.g., "greet"). This will form part of the invocation URL.

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
    Confirm by typing `yes`. Terraform will output the invocation URL for the API Gateway endpoint (`apigw_invoke_url_on_path1`).

## Verifying the Setup

After successful deployment:

1.  **Test with `curl` (or a web browser):**
    *   Use the `apigw_invoke_url_on_path1` value from the Terraform output.
    *   **Without Query Parameter:**
        ```bash
        curl "<apigw_invoke_url_on_path1_output_value>"
        # Example: curl https://abcdef123.execute-api.us-east-1.amazonaws.com/demo33-stage1/greet
        ```
        **Expected Output:** `{"message": "hello world"}`
    *   **With Query Parameter:**
        ```bash
        curl "<apigw_invoke_url_on_path1_output_value>?name=YourName"
        # Example: curl "https://abcdef123.execute-api.us-east-1.amazonaws.com/demo33-stage1/greet?name=Terraform"
        ```
        **Expected Output:** `{"message": "hello world Terraform"}` (or whatever name you provided).

2.  **Check API Gateway Execution Logs in CloudWatch (if enabled):**
    *   Navigate to the AWS CloudWatch console.
    *   Go to "Log groups".
    *   Find and select the log group (e.g., `/aws/apigateway/demo33_rest_api_access_logs` or as configured in stage settings).
    *   If execution/access logging is fully enabled in the API Gateway stage settings (which might require more configuration than just creating the log group and role), you should see log streams detailing the requests and responses.

3.  **Check Lambda Execution Logs in CloudWatch:**
    *   Navigate to the AWS Lambda console and select the `demo33_lambda_py` function.
    *   Go to the "Monitor" tab and click "View CloudWatch logs".
    *   This will take you to the log group `/aws/lambda/demo33_lambda_py`.
    *   You should see log streams containing execution details, including any `print()` statements from your Lambda code (e.g., the event object, which will include the query string parameters). Because `AWSLambdaBasicExecutionRole` is attached, these logs should be reliably written.

This setup provides a functional serverless API endpoint capable of processing query string parameters and demonstrates the more detailed configuration involved with API Gateway REST APIs (v1).
