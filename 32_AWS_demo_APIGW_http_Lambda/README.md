# AWS API Gateway HTTP with Lambda Demo

This Terraform project demonstrates a serverless architecture using AWS API Gateway HTTP API integrated with AWS Lambda function for handling HTTP requests.

## Architecture Overview

- **API Gateway HTTP API** for handling HTTP requests
- **Lambda Function** for processing requests and returning responses
- **CloudWatch Logs** for API Gateway access logging
- **IAM Role** with appropriate permissions for Lambda execution

## Infrastructure Components

### API Gateway
- HTTP API Gateway with configurable path routing
- CloudWatch access logging enabled
- Auto-deployment stage configuration

### Lambda Function
- Python 3.11 runtime
- Simple "hello world" response handler
- Environment variables support
- Automatic ZIP packaging from source code

### Logging & Monitoring
- CloudWatch log group for API Gateway access logs
- Detailed request/response logging with JSON format

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- Python source code for Lambda function

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region
   - API Gateway path for Lambda integration

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
| `03_lambda.tf` | Lambda function and IAM role |
| `04_api_gateway_http.tf` | HTTP API Gateway configuration |
| `lambda.py` | Lambda function source code |

## Usage

After deployment, Terraform will output a test command. You can test the API using:

```bash
curl -i https://<API-ID>.execute-api.<REGION>.amazonaws.com/<PATH>
```

The Lambda function returns a simple JSON response:
```json
{"message": "hello world"}
```

## API Gateway Features

- **HTTP API**: Modern, faster, and cost-effective API Gateway
- **ANY Method**: Accepts all HTTP methods (GET, POST, PUT, DELETE, etc.)
- **Proxy Integration**: Direct integration with Lambda using AWS_PROXY
- **Access Logging**: Comprehensive request/response logging
- **Auto Deploy**: Automatic deployment of API changes

## Lambda Function Details

- **Runtime**: Python 3.11
- **Handler**: `lambda.lambda_handler`
- **Packaging**: Automatic ZIP creation from source code
- **Permissions**: API Gateway invoke permissions configured
- **Environment**: Configurable environment variables

## Security Features

- IAM role with minimal required permissions for Lambda
- API Gateway permissions properly configured
- CloudWatch logging for monitoring and debugging

## Monitoring

View API Gateway access logs:
```bash
aws logs tail /aws/apigateway/demo32 --follow
```

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- The Lambda function source code is automatically packaged into a ZIP file
- API Gateway HTTP API is more cost-effective than REST API for simple use cases
- CloudWatch logs retention is set to 14 days
- The API supports all HTTP methods through the ANY route