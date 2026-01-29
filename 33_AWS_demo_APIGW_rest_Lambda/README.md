# AWS API Gateway REST with Lambda Demo

This Terraform project demonstrates a serverless architecture using AWS API Gateway REST API integrated with AWS Lambda function for handling HTTP requests.

## Architecture Overview

- **API Gateway REST API** with regional endpoint configuration
- **Lambda Function** for processing GET requests and returning responses
- **CloudWatch Logs** for API Gateway access logging
- **IAM Roles** with appropriate permissions for Lambda and API Gateway

## Infrastructure Components

### API Gateway
- REST API Gateway with configurable resource path
- GET method support with query parameter handling
- Regional endpoint configuration
- CloudWatch logging integration

### Lambda Function
- Python 3.11 runtime
- Query parameter processing capability
- Automatic ZIP packaging from source code
- Environment variables support

### Logging & Monitoring
- CloudWatch log group for API Gateway logs
- IAM role for API Gateway CloudWatch integration

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
   - API Gateway resource path

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
| `04_api_gateway_rest.tf` | REST API Gateway configuration |
| `lambda.py` | Lambda function source code |

## Usage

After deployment, Terraform will output test commands. You can test the API using:

```bash
# Basic request
curl -i https://<API-ID>.execute-api.<REGION>.amazonaws.com/demo33-stage1/<PATH>

# Request with query parameter
curl -i https://<API-ID>.execute-api.<REGION>.amazonaws.com/demo33-stage1/<PATH>?name=christophe
```

## API Gateway Features

- **REST API**: Full-featured API Gateway with complete REST capabilities
- **GET Method**: Configured for GET requests with query parameter support
- **Regional Endpoint**: Optimized for regional access
- **Proxy Integration**: AWS_PROXY integration with Lambda
- **Staged Deployment**: Deployed to `demo33-stage1` stage

## Lambda Function Details

- **Runtime**: Python 3.11
- **Handler**: `lambda.lambda_handler`
- **Integration**: AWS_PROXY with API Gateway
- **Permissions**: API Gateway invoke permissions configured
- **Query Parameters**: Supports processing of URL query parameters

## Security Features

- IAM roles with minimal required permissions
- API Gateway CloudWatch logging permissions
- Lambda execution permissions properly scoped

## Monitoring

View API Gateway logs:
```bash
aws logs tail /aws/apigateway/demo33 --follow
```

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- REST API provides more features than HTTP API but at higher cost
- The API is deployed to a named stage (`demo33-stage1`)
- CloudWatch logs retention is set to 14 days
- Lambda function can process query parameters from the request