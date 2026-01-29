# AWS Lambda Function Demo

This Terraform project demonstrates AWS Lambda function deployment with IAM roles and basic Python code execution.

## Architecture Overview

- **AWS Lambda function** with Python 3.11 runtime
- **IAM role** with basic execution permissions
- **Automated deployment** with source code packaging
- **Environment variables** configuration

## Infrastructure Components

### Serverless Compute
- **Lambda Function**: Serverless Python function
- **Runtime**: Python 3.11 environment
- **Handler**: Entry point for function execution
- **Environment Variables**: Configuration parameters

### Security
- **IAM Role**: Lambda execution role with basic permissions
- **Managed Policies**: Pre-configured AWS policies for Lambda execution

### Deployment
- **Source Code Packaging**: Automatic ZIP file creation
- **Version Control**: Source code hash tracking for updates

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- Basic Python knowledge

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan the deployment**
   ```bash
   terraform plan
   ```

5. **Deploy the infrastructure**
   ```bash
   terraform apply
   ```

## Configuration Files

| File | Purpose |
|------|---------| 
| `01_variables.tf` | Variable definitions |
| `02_provider.tf` | AWS provider configuration |
| `03_iam_role.tf` | IAM role for Lambda execution |
| `04_lambda.tf` | Lambda function configuration |
| `lambda.py` | Python source code |

## Usage

After deployment, you can test the Lambda function:

### AWS CLI Testing
```bash
# Invoke the function
aws lambda invoke --function-name demo29_lambda --payload '{"test": "data"}' response.json

# View the response
cat response.json

# Check function logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/demo29_lambda
```

### AWS Console Testing
1. Navigate to AWS Lambda console
2. Find the `demo29_lambda` function
3. Use the "Test" tab to create and run test events
4. View execution results and logs

### Function Modification
To update the Lambda function:
1. Modify `lambda.py`
2. Run `terraform apply`
3. Terraform will automatically repackage and deploy the updated code

## Lambda Function Features

- **Event Processing**: Handles JSON events passed to the function
- **Logging**: Automatic CloudWatch Logs integration
- **Environment Variables**: Configurable runtime parameters
- **Error Handling**: Basic error response structure
- **Serverless**: No server management required

## Python Code Structure

The Lambda function (`lambda.py`) includes:
- **Event Handler**: Main entry point (`lambda_handler`)
- **Event Logging**: Prints received events for debugging
- **Response Format**: Returns proper HTTP-style responses
- **Commented Code**: Examples for SNS integration

## Security Features

- IAM role with minimal required permissions
- Automatic CloudWatch Logs access
- Secure environment variable handling
- AWS managed policies for Lambda execution

## Monitoring and Debugging

- **CloudWatch Logs**: Automatic function logging
- **CloudWatch Metrics**: Function execution metrics
- **Error Tracking**: Failed invocation monitoring
- **Duration Tracking**: Execution time monitoring

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Lambda function is automatically packaged from `lambda.py`
- Source code changes trigger automatic redeployment
- Function includes basic error handling and logging
- Environment variables can be configured in Terraform
- CloudWatch Logs are created automatically
- Function supports synchronous and asynchronous invocation