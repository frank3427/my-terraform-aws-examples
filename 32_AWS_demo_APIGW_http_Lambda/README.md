# Terraform AWS: API Gateway HTTP API with Lambda Integration

This Terraform project demonstrates how to provision a simple serverless application using an **AWS Lambda function** integrated with an **AWS API Gateway HTTP API (v2)**.

## Purpose

The primary goal of this project is to illustrate a lightweight and cost-effective way to expose a Lambda function as an HTTP endpoint. API Gateway HTTP APIs are designed for low-latency, high-performance serverless workloads and offer a simpler configuration experience compared to REST APIs (v1).

This project showcases:
*   Creating a Python Lambda function.
*   Setting up an API Gateway HTTP API (v2).
*   Integrating the API Gateway with the Lambda function using `AWS_PROXY` integration.
*   Defining a route that triggers the Lambda for any HTTP method on a specific path.
*   Configuring access logging for the API Gateway.
*   Granting necessary permissions for API Gateway to invoke the Lambda function.

## Key Components

1.  **AWS Lambda Function (`aws_lambda_function.demo32`):**
    *   **Runtime:** Python 3.11 (`python3.11`).
    *   **Handler:** `lambda.lambda_handler` (points to the `lambda_handler` function within the `lambda.py` file).
    *   **Source Code (`lambda.py`):**
        *   A basic Python function that returns a simple JSON message: `{"message": "hello world"}`.
        *   The `lambda.py` script is packaged into a zip file (`lambda_function_payload.zip`) by Terraform using the `data "archive_file"` resource and then uploaded as the Lambda's deployment package.
    *   **IAM Role (`aws_iam_role.demo32`):**
        *   An IAM role is created for the Lambda function to assume, allowing it to run.
        *   **Note on Permissions:** The current IAM role configuration for this Lambda function is very minimal. It does **not** explicitly attach standard Lambda policies like `AWSLambdaBasicExecutionRole`. This policy is typically required to grant the Lambda function permission to write logs to Amazon CloudWatch Logs. Without it, Lambda execution logs might not be created, or the function might rely on very basic default permissions which could be insufficient. For production or debugging, attaching `AWSLambdaBasicExecutionRole` or a more specific custom policy for logging is highly recommended.
2.  **API Gateway HTTP API (`aws_apigatewayv2_api.demo32`):**
    *   **Protocol Type:** `HTTP`. This specifies that an API Gateway v2 HTTP API is being created, distinct from the older REST API (v1).
    *   **Integration (`aws_apigatewayv2_integration.demo32`):**
        *   **Type:** `AWS_PROXY`. This is a standard integration type for Lambda, where API Gateway passes the entire request to the Lambda function and the Lambda function's response is mapped back to an HTTP response.
        *   **`payload_format_version = "2.0"`:** Specifies the payload format version for the Lambda proxy integration. Version 2.0 provides a more structured event payload to the Lambda function.
        *   Connects to the `aws_lambda_function.demo32`.
    *   **Route (`aws_apigatewayv2_route.demo32_route_to_lambda`):**
        *   A single route is defined: `ANY /${var.apigw_path1}`.
        *   `ANY`: This means the route will match any HTTP method (GET, POST, PUT, DELETE, etc.).
        *   `/${var.apigw_path1}`: The path part of the URL that triggers this route (e.g., `/hello`). The actual path is configurable via the `apigw_path1` variable.
        *   This route is configured to target the Lambda integration defined above.
    *   **Stage (`aws_apigatewayv2_stage.demo32_default_stage`):**
        *   A default stage named `$default` is automatically created.
        *   `auto_deploy = true`: Enables automatic deployment of changes to this stage when the API configuration is updated.
        *   **Access Logging:**
            *   Configured to send structured JSON access logs to a dedicated CloudWatch Log Group named `/aws/apigateway/demo32_http_api_access_logs` (name derived from `local.apigw_name`). This is very useful for monitoring and debugging API requests.
            *   The log format includes details like request ID, IP address, HTTP method, path, status code, and latency.
3.  **Lambda Permission (`aws_lambda_permission.demo32_apigw_can_invoke_lambda`):**
    *   This resource grants the API Gateway service (`apigateway.amazonaws.com`) the necessary permission to invoke the `aws_lambda_function.demo32` Lambda function. This is essential for the integration to work.

## Highlights

*   **API Gateway HTTP API (v2):** Utilizes the newer, more cost-effective, and lower-latency HTTP API type from API Gateway.
*   **`ANY` Method Route:** Demonstrates a flexible route configuration that catches all HTTP methods on a given path and directs them to a single Lambda backend.
*   **Structured Access Logging:** API Gateway access logs are configured to be sent to CloudWatch Logs in a structured JSON format, facilitating easier analysis and monitoring.
*   **Lambda IAM Permissions Note:** Explicitly calls out the minimal nature of the Lambda's IAM role in this example, particularly concerning logging permissions, which is an important consideration for real-world applications.

## Key Configuration Variables

*   `aws_region`: The AWS region where all resources will be deployed (e.g., "us-east-1").
*   `apigw_path1`: The path component for the API Gateway route (e.g., "hello"). This will form part of the invocation URL (e.g., `https://<api-id>.execute-api.<region>.amazonaws.com/hello`).

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
    *   Make a request to this URL. Since the route is `ANY`, you can use GET, POST, etc.
        ```bash
        curl <apigw_invoke_url_on_path1_output_value>
        # Example: curl https://abcdef123.execute-api.us-east-1.amazonaws.com/hello
        ```
    *   **Expected Output:** You should receive the JSON response from the Lambda function:
        ```json
        {"message": "hello world"}
        ```

2.  **Check API Gateway Access Logs in CloudWatch:**
    *   Navigate to the AWS CloudWatch console.
    *   Go to "Log groups".
    *   Find and select the log group named `/aws/apigateway/demo32_http_api_access_logs` (or similar, based on `local.apigw_name`).
    *   You should see log streams containing structured JSON entries for each request made to your API Gateway endpoint. These logs provide details about the request and response.

3.  **Check Lambda Execution Logs in CloudWatch (Permissions Permitting):**
    *   Navigate to the AWS Lambda console and select the `demo32_lambda` function.
    *   Go to the "Monitor" tab and click "View CloudWatch logs".
    *   This will take you to the log group for the Lambda function (usually `/aws/lambda/demo32_lambda`).
    *   **Note:** As highlighted, the IAM role for the Lambda in this project is minimal. If `AWSLambdaBasicExecutionRole` or equivalent permissions were not implicitly granted or are missing, you might not see detailed execution logs here (like the `event` being printed by the Lambda code). If logs are present, you can see the event data received by the Lambda function.

Successful `curl` response and the presence of API Gateway access logs confirm the primary functionality. The presence of Lambda execution logs depends on the effective permissions of its IAM role.
