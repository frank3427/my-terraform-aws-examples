# Terraform AWS: Simple Python Lambda Function

This Terraform project demonstrates how to provision a basic AWS Lambda function written in Python. It covers the creation of the Lambda function itself, the necessary IAM role, and the packaging of the Python source code.

## Purpose

The primary goal of this project is to illustrate the fundamental steps involved in deploying a serverless function using AWS Lambda with Terraform. This includes:
*   Defining an IAM Role that the Lambda function will assume for permissions.
*   Packaging Python code into a deployable zip file.
*   Creating the Lambda function resource with necessary configurations like runtime, handler, and environment variables.
*   Understanding how to invoke and verify the Lambda function.

## Key Components

1.  **IAM Role for Lambda (`aws_iam_role.demo29_for_lambda`):**
    *   An IAM role is created that the Lambda service (`lambda.amazonaws.com`) can assume to execute the function.
    *   **Note on Permissions (Current Configuration):**
        *   This project currently attaches the AWS managed policies `AmazonEC2RoleforSSM` and `AmazonSSMManagedInstanceCore` to the Lambda's IAM role.
        *   **These policies are typically used for EC2 instances managed by AWS Systems Manager and are overly permissive for a simple Lambda function like this example.** They grant permissions related to SSM and EC2 management which are not needed by this Lambda.
        *   For a basic Lambda function that only needs to write logs to CloudWatch (which this function does by logging the event), the AWS managed policy `AWSLambdaBasicExecutionRole` would be a more appropriate and secure choice, adhering to the principle of least privilege. This project uses the current policies for demonstration purposes as per its original setup but it's important to be aware of this.
2.  **Lambda Function (`aws_lambda_function.demo29`):**
    *   **Function Name:** `demo29_lambda`.
    *   **Runtime:** Python 3.11 (`python3.11`).
    *   **Handler:** `lambda.lambda_handler`. This tells Lambda to execute the `lambda_handler` function within the `lambda.py` file.
    *   **Source Code:**
        *   The Python code is located in the `lambda.py` file.
        *   Terraform uses the `data "archive_file"` resource to package the `lambda.py` script into a zip file named `lambda_function_payload.zip`.
        *   This zip file is then specified as the source code for the Lambda function.
    *   **Environment Variables:**
        *   Includes an example environment variable: `foo = "bar"`. Lambda functions can access these variables at runtime.
3.  **Python Lambda Code (`lambda.py`):**
    *   **Functionality:** It's a simple Python function designed to:
        1.  Log the `event` object it receives upon invocation. This is useful for seeing what data triggers the Lambda.
        2.  Return a static JSON response: `{"statusCode": 200, "body": "Hello from Lambda!"}`. This is a common response format for Lambda functions integrated with API Gateway, though this project doesn't include API Gateway.
    *   **Commented-out Code:** The `lambda.py` file contains some commented-out code related to processing SNS (Simple Notification Service) events. This code is not active in the current deployment and serves only as a placeholder or example of potential further development.

## Highlights

*   **Basic Lambda Deployment Structure:** Shows the core Terraform resources (`aws_iam_role`, `aws_lambda_function`, `data "archive_file"`) needed to deploy a Lambda function.
*   **Code Packaging:** Illustrates how source code is packaged into a zip file for deployment.
*   **IAM Role and Permissions:** Demonstrates the creation of an IAM role for Lambda, with an important note on the currently configured (overly permissive) policies.
*   **Simple Python Handler:** Provides a basic Python function that logs events and returns a response.

## Key Configuration Variables

*   `aws_region`: The AWS region where the Lambda function and associated IAM role will be deployed (e.g., "us-east-1"). Most other aspects like function name, handler, and runtime are hardcoded in this example for simplicity.

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
    Provision the AWS Lambda function and IAM role.
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`.

## Verifying the Lambda

After successful deployment, you can invoke and verify the Lambda function in several ways:

### 1. Using the AWS Management Console:

*   Navigate to the **AWS Lambda** console.
*   Find and select the function named `demo29_lambda`.
*   Go to the **"Test"** tab.
*   You can create a new test event. For this function, the content of the event doesn't significantly alter its basic response, so a simple JSON like `{}` or the default "hello-world" event template will suffice.
*   Click the **"Test"** button.
*   **Check Execution Results:**
    *   **Response:** You should see the function's output: `{"statusCode": 200, "body": "Hello from Lambda!"}`.
    *   **Log output:** The logs section will show the execution details, including the `event` object that was logged by the Python script.
*   **Check CloudWatch Logs:**
    *   Click the "Monitor" tab in the Lambda console, then "View CloudWatch logs".
    *   This will take you to the log group for your Lambda function (e.g., `/aws/lambda/demo29_lambda`).
    *   Examine the log streams to see the logged event and other execution details.

### 2. Using the AWS CLI:

*   Ensure your AWS CLI is configured with appropriate credentials and region.
*   Invoke the Lambda function:
    ```bash
    aws lambda invoke \
        --function-name demo29_lambda \
        --payload '{}' \
        output.json
    ```
    *   `--payload '{}'` sends an empty JSON object as the event.
    *   `output.json` is the file where the Lambda function's response will be saved.
*   **Check the Output File (`output.json`):**
    It should contain:
    ```json
    {"statusCode": 200, "body": "Hello from Lambda!"}
    ```
*   **Check CloudWatch Logs:**
    You can also query CloudWatch Logs via the AWS CLI if needed, or use the console as described above. The logs will contain the `event` printed by the `lambda_handler`.

This process confirms that the Lambda function is deployed correctly, can be invoked, executes its code (logging the event), and returns the expected response. Remember to review and adjust IAM permissions for production workloads.
