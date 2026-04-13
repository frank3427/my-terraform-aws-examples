# AWS API Gateway REST with Lambda Demo

Terraform project deploying a serverless API with availability monitoring via CloudWatch Synthetics.

## Architecture

```
CloudWatch Synthetics Canary (every 1 min)
        |
        v
API Gateway REST API (regional)
        |
        v
Lambda Function (Python 3.11)
        |
        v
CloudWatch Logs
```

## Infrastructure Components

| File | Resources |
|------|-----------|
| `01_variables.tf` | Variable definitions |
| `02_provider.tf` | AWS provider configuration |
| `03_lambda.tf` | Lambda function + IAM role |
| `04_api_gateway_rest.tf` | REST API Gateway, stage, CloudWatch logs |
| `05_cwatch_api_canary.tf` | CloudWatch Synthetics canary + S3 artifacts bucket |
| `lambda.py` | Lambda function source code |

### Lambda
- Runtime: Python 3.11
- Handler: `lambda.lambda_handler`
- Packaged automatically from `lambda.py` via `archive_file`
- Supports query parameters (e.g. `?name=christophe`)

### API Gateway
- REST API with regional endpoint
- GET method on configurable path (`apigw_path1`)
- AWS_PROXY integration with Lambda
- Stage: `demo33-stage1`
- Access logs to CloudWatch (`/aws/apigateway/demo33`, 14-day retention)

### CloudWatch Synthetics Canary
- Runs every minute (`rate(1 minute)`)
- Hits the API Gateway endpoint and asserts HTTP 200
- Runtime: `syn-nodejs-puppeteer-9.1`
- Artifacts (screenshots, logs) stored in a private S3 bucket

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials

## Setup

```bash
cp terraform.tfvars.TEMPLATE terraform.tfvars
# edit terraform.tfvars: set aws_region and apigw_path1

terraform init
terraform apply
```

## Usage

After `terraform apply`, the outputs provide ready-to-run curl commands:

```bash
curl -i https://<API-ID>.execute-api.<REGION>.amazonaws.com/demo33-stage1/<PATH>
curl -i https://<API-ID>.execute-api.<REGION>.amazonaws.com/demo33-stage1/<PATH>?name=christophe
```

View API Gateway logs:
```bash
aws logs tail /aws/apigateway/demo33 --follow
```

View canary results in the AWS console (URL provided as Terraform output `canary_console_url`).

## Cleanup

```bash
terraform destroy
```

## Notes

- CloudWatch Synthetics canary runs as a Lambda function internally — the IAM role grants it S3, CloudWatch Logs, and CloudWatch Metrics permissions
- S3 bucket for canary artifacts is named `demo33-canary-artifacts-<account-id>` and is destroyed with `terraform destroy`
- Log retention is 14 days
