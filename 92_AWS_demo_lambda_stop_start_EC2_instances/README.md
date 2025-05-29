## How do I stop and start Amazon EC2 instances at regular intervals using Lambda?

This Terraform project provisions the AWS Lambda functions and necessary IAM permissions as described in the AWS Knowledge Center article:
[How do I stop and start Amazon EC2 instances at regular intervals using Lambda?](https://aws.amazon.com/premiumsupport/knowledge-center/start-stop-lambda-eventbridge/)

Refer to this article for the detailed logic within the Lambda functions and for instructions on scheduling them with Amazon EventBridge.

## Overview

This project automates the setup of two AWS Lambda functions: one to **stop** specified EC2 instances and another to **start** them. This is a common pattern used for cost optimization, allowing EC2 instances to run only during specific hours or when needed.

**Key Points:**
*   This Terraform configuration creates the Lambda functions and their required IAM permissions.
*   The specific EC2 instances to be targeted and their region are **hardcoded** within the Terraform files for this demonstration.
*   **Scheduling of these Lambda functions is NOT handled by this Terraform project.** To automate the start/stop operations (e.g., daily), you would typically use Amazon EventBridge (formerly CloudWatch Events) as outlined in the linked AWS Knowledge Center article.

## Key Components

1.  **Lambda Functions:**
    *   **`demo92_stop_ec2` (from `lambda_function_stop.zip`):**
        *   **Terraform Resource:** `aws_lambda_function.lambda_stop_ec2`
        *   **Purpose:** Stops the EC2 instances defined in its environment variables.
        *   **Runtime:** Python 3.8
        *   **Handler:** `lambda_function_stop.lambda_handler`
    *   **`demo92_start_ec2` (from `lambda_function_start.zip`):**
        *   **Terraform Resource:** `aws_lambda_function.lambda_start_ec2`
        *   **Purpose:** Starts the EC2 instances defined in its environment variables.
        *   **Runtime:** Python 3.8
        *   **Handler:** `lambda_function_start.lambda_handler`
    *   **Environment Variables (Hardcoded in Terraform Configuration):**
        Both Lambda functions are configured with the following environment variables directly in the `.tf` files:
        *   `REGION`: The AWS region where the target EC2 instances reside (e.g., "eu-west-1").
        *   `INSTANCE_IDS`: A comma-separated string of specific EC2 instance IDs to be acted upon (e.g., "i-0abcdef1234567890,i-0fedcba9876543210").

2.  **IAM Role and Policy:**
    *   **IAM Role (`aws_iam_role.demo92_iam_for_lambda`):**
        *   Created to be assumed by the Lambda service (`lambda.amazonaws.com`).
    *   **Custom IAM Policy (`aws_iam_policy.demo92_lambda_policy_stop_start_ec2`):**
        *   Attached to the IAM role.
        *   Grants the following permissions:
            *   **CloudWatch Logs:** `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` (allows Lambda functions to write their execution logs).
            *   **EC2 Actions:** `ec2:Start*`, `ec2:Stop*` (allows Lambda functions to start and stop EC2 instances).
            *   **Resource Scope:** The EC2 actions in this policy are configured for `Resource: "*"`, meaning the Lambda functions, by this policy alone, have permission to start/stop *any* EC2 instance in the account and region where they are deployed. For production, you might restrict this to specific instances or instances with specific tags.

3.  **Lambda Source Code (Pre-built Zip Files):**
    *   The Python source code for these Lambda functions is provided within this project as pre-built zip files: `lambda_function_start.zip` and `lambda_function_stop.zip`.
    *   The internal logic of these Python scripts (typically using `boto3`) involves:
        1.  Reading the `REGION` and `INSTANCE_IDS` environment variables.
        2.  Splitting the `INSTANCE_IDS` string into a list of individual instance IDs.
        3.  Iterating through this list.
        4.  For each instance ID, calling the appropriate `boto3` EC2 client method: `ec2.stop_instances()` for the stop function, or `ec2.start_instances()` for the start function.
        5.  Logging the actions performed to CloudWatch Logs.
    *   For the detailed Python code implementation, please refer to the linked **AWS Knowledge Center article**. The article may also discuss alternative strategies like tag-based instance selection, which is a more flexible approach than hardcoding instance IDs.

## Configuration Notes (Hardcoded Values & Targeting)

*   **CRITICAL:** The AWS region (`REGION` environment variable) and the target EC2 instance IDs (`INSTANCE_IDS` environment variable) are **hardcoded within the `aws_lambda_function` resource definitions in the `03_lambda.tf` file.**
    ```terraform
    # Example from 03_lambda.tf:
    environment {
      variables = {
        REGION       = "eu-west-1" # Target EC2 region
        INSTANCE_IDS = "i-xxxxxxxxxxxxxxxxx,i-yyyyyyyyyyyyyyyyy" # Target EC2 instance IDs
      }
    }
    ```
*   To make these Lambda functions operate on **your specific EC2 instances** and in **your desired region**, you **MUST modify these hardcoded values directly in the `03_lambda.tf` file** before running `terraform apply`.
*   For more dynamic configurations, especially in shared modules or larger environments, these values would typically be passed as Terraform variables rather than being hardcoded.

## Scheduling Lambdas with EventBridge (Not Included in Terraform)

This Terraform project **only provisions the Lambda functions and their necessary IAM permissions.** It does **not** automatically schedule them to run.

To automate the execution of these Lambda functions at regular intervals (e.g., stopping instances every evening and starting them every morning), you need to:
1.  Navigate to the **Amazon EventBridge (formerly CloudWatch Events)** console in the AWS region where your Lambda functions are deployed.
2.  Create two EventBridge rules:
    *   **One rule for stopping instances:**
        *   Define a schedule (e.g., using a cron expression like `cron(0 18 * * ? *)` to run at 6 PM UTC daily).
        *   Set the target as the `demo92_stop_ec2` Lambda function.
    *   **One rule for starting instances:**
        *   Define a schedule (e.g., `cron(0 8 * * ? *)` to run at 8 AM UTC daily).
        *   Set the target as the `demo92_start_ec2` Lambda function.

The linked AWS Knowledge Center article provides detailed steps for creating these EventBridge rules.

## Usage

1.  **Modify Lambda Environment Variables:**
    *   Open the `03_lambda.tf` file.
    *   Update the `REGION` and `INSTANCE_IDS` environment variables within both `aws_lambda_function.lambda_stop_ec2` and `aws_lambda_function.lambda_start_ec2` resources to match your target AWS region and EC2 instance IDs.
2.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
3.  **Plan Changes:**
    Review the resources that Terraform will create.
    ```bash
    terraform plan
    ```
4.  **Apply Changes:**
    Provision the AWS Lambda functions and IAM role/policy.
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`.

## Verifying the Lambdas

After deployment, you can test the Lambda functions manually before setting up EventBridge schedules:

1.  **Manual Invocation for Testing:**
    *   Go to the **AWS Lambda console**.
    *   Find and select one of the functions (e.g., `demo92_stop_ec2` or `demo92_start_ec2`).
    *   Navigate to the **"Test"** tab.
    *   Create a new test event. An empty JSON object `{}` is usually sufficient for the "Payload" as these functions primarily rely on their environment variables.
    *   Click the **"Test"** button to manually invoke the function.

2.  **Check EC2 Instance State:**
    *   Go to the **EC2 console** in the region you specified in the Lambda's `REGION` environment variable.
    *   Verify that the EC2 instances listed in the `INSTANCE_IDS` environment variable have changed their state (i.e., stopped after invoking the stop Lambda, or started after invoking the start Lambda).

3.  **Check CloudWatch Logs:**
    *   In the AWS Lambda console, under the "Monitor" tab for the function, click "View CloudWatch logs".
    *   This will take you to the log groups for the Lambda functions (e.g., `/aws/lambda/demo92_stop_ec2` and `/aws/lambda/demo92_start_ec2`).
    *   Examine the log streams for execution details, including which instances were targeted and the success or failure of the start/stop API calls. The IAM policy `AWSLambdaBasicExecutionRole` (or the custom policy with logging permissions) ensures these logs are written.

Once manual testing is successful, proceed to set up the Amazon EventBridge schedules for automated operation as described in the AWS Knowledge Center article.
