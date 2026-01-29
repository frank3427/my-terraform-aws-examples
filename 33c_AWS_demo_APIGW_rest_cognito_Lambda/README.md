# AWS API Gateway REST with Cognito Authentication and Lambda Demo

This Terraform project demonstrates a serverless architecture using AWS API Gateway REST API with Amazon Cognito User Pool authentication integrated with AWS Lambda function.

## Architecture Overview

- **API Gateway REST API** with regional endpoint and Cognito User Pool authentication
- **Amazon Cognito User Pool** for user authentication and JWT token management
- **Lambda Function** for processing authenticated GET requests
- **CloudWatch Logs** for API Gateway access logging
- **IAM Roles** with appropriate permissions for Lambda and API Gateway

## Infrastructure Components

### API Gateway
- REST API Gateway with Cognito User Pool authorizer
- GET method with mandatory JWT token authentication
- Regional endpoint configuration
- CloudWatch logging with detailed access logs

### Authentication & Authorization
- Cognito User Pool with configurable OAuth flows
- User Pool Client for API Gateway integration
- Automatic user creation with generated password
- JWT token-based authentication

### Lambda Function
- Python 3.11 runtime
- AWS_PROXY integration with API Gateway
- Automatic ZIP packaging from source code
- Environment variables support

### Logging & Monitoring
- CloudWatch log group for API Gateway logs
- Detailed access logging with user context
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
   - Cognito user name
   - Project prefix
   - CloudWatch logs retention period

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
| `04_cognito_user_pool.tf` | Cognito User Pool and client configuration |
| `05_api_gateway_rest.tf` | REST API Gateway with Cognito authorizer |
| `06_outputs.tf` | Output values and authentication instructions |
| `lambda.py` | Lambda function source code |

## Usage

After deployment, Terraform will output detailed instructions for testing:

### 1. Test Unauthorized Access (will fail)
```bash
curl -i https://<API-ID>.execute-api.<REGION>.amazonaws.com/demo33c-stage1/<PATH>
```

### 2. Generate Access Token
```bash
aws cognito-idp admin-initiate-auth \
    --region <REGION> \
    --client-id <CLIENT-ID> \
    --user-pool-id <USER-POOL-ID> \
    --auth-flow ADMIN_NO_SRP_AUTH \
    --auth-parameters USERNAME=<USERNAME>,PASSWORD=<PASSWORD>
```

### 3. Test Authorized Access
```bash
TOKEN=<IdToken-from-previous-command>
curl -i \
    -H "Authorization: Bearer $TOKEN" \
    https://<API-ID>.execute-api.<REGION>.amazonaws.com/demo33c-stage1/<PATH>
```

## API Gateway Features

- **REST API**: Full-featured API Gateway with Cognito authentication
- **Cognito Authorizer**: JWT token validation using Cognito User Pool
- **Regional Endpoint**: Optimized for regional access
- **AWS_PROXY Integration**: Direct integration with Lambda
- **Staged Deployment**: Deployed to `demo33c-stage1` stage
- **Access Logging**: Comprehensive request/response logging

## Cognito Features

- **User Pool**: Centralized user directory
- **OAuth Flows**: Support for implicit and authorization code flows
- **JWT Tokens**: Industry-standard token-based authentication
- **User Management**: Automatic user creation with secure passwords
- **Client Configuration**: API Gateway-specific client settings

## Security Features

- **JWT Authentication**: Industry-standard token-based security
- **Cognito User Pool**: Managed user authentication service
- **IAM Roles**: Minimal required permissions
- **Secure Password Generation**: Random passwords with complexity requirements
- **Token Validation**: API Gateway validates JWT tokens before Lambda invocation

## Lambda Function Details

- **Runtime**: Python 3.11
- **Handler**: `lambda.lambda_handler`
- **Integration**: AWS_PROXY with API Gateway
- **Permissions**: API Gateway invoke permissions configured
- **User Context**: Access to authenticated user information via JWT claims

## Monitoring

View API Gateway logs:
```bash
aws logs tail /aws/apigateway/<PROJECT-PREFIX> --follow
```

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- User password is automatically generated and displayed in Terraform output
- JWT tokens have expiration times managed by Cognito
- The API returns 401 Unauthorized without valid JWT token
- CloudWatch logs include user context from JWT tokens
- OAuth flows are configured for future web application integration