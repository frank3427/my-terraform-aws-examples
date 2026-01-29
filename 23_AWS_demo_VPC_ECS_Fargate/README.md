# AWS VPC with ECS Fargate Demo

This Terraform project demonstrates AWS infrastructure setup with VPC, ECS Fargate cluster, containerized applications, and AWS Fault Injection Simulator (FIS) for chaos engineering.

## Architecture Overview

- **VPC** with public and private subnets across multiple availability zones
- **ECS Fargate cluster** for serverless container orchestration
- **Application Load Balancer** for traffic distribution to containers
- **AWS FIS experiment** for chaos engineering and resilience testing
- **CloudWatch logging** for monitoring and observability

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnets across multiple availability zones
- Private subnets for future use

### Container Platform
- **ECS Cluster**: Fargate-based serverless container platform
- **Task Definition**: Nginx web server container configuration
- **ECS Service**: Manages desired container instances with load balancer integration
- **Capacity Providers**: Mix of Fargate and Fargate Spot for cost optimization

### Load Balancing
- Application Load Balancer with health checks
- Target group for container registration
- Cross-zone load balancing

### Chaos Engineering
- **AWS FIS Experiment Template**: Stop ECS tasks in specific availability zone
- **CloudWatch Logs**: FIS experiment logging
- **IAM Role**: Permissions for FIS to interact with ECS

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- Docker knowledge for container concepts

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region
   - CIDR blocks for VPC and subnets
   - Authorized IP addresses for load balancer access
   - Availability zone for FIS experiments

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
| `03_network.tf` | VPC, subnets, and networking |
| `04_elb_for_ecs_service.tf` | Application Load Balancer setup |
| `05_ecs_fargate.tf` | ECS cluster, task definition, and service |
| `06_fis_experiment_template.tf` | AWS FIS chaos engineering setup |

## Usage

After deployment, wait a few minutes for containers to start, then:

### Web Access
- Access the containerized application: `http://<ALB-DNS-NAME>`
- Each request shows which container handled it

### ECS Management
```bash
# List running tasks
aws ecs list-tasks --cluster demo23-cluster --service-name demo23-svc2

# Describe service
aws ecs describe-services --cluster demo23-cluster --services demo23-svc2

# Scale service
aws ecs update-service --cluster demo23-cluster --service demo23-svc2 --desired-count 5
```

### Chaos Engineering with FIS
```bash
# Start FIS experiment to stop tasks in specific AZ
aws fis start-experiment --experiment-template-id <TEMPLATE-ID>

# Monitor experiment
aws fis get-experiment --id <EXPERIMENT-ID>
```

### Helper Scripts
The `scripts/` directory contains useful management scripts:
- `01_check_access_web.sh`: Test web access
- `02_cli_describe_service.sh`: Get service details
- `03_cli_list_tasks.sh`: List running tasks
- `04_cli_kill_task.sh`: Terminate specific task
- `11_kill_ecs_tasks_in_AZ_remove_subnet.sh`: Chaos testing

## Security Features

- Security groups with minimal required access
- IP-based access restrictions for load balancer
- IAM roles with least privilege for FIS
- Container isolation with Fargate

## ECS Fargate Features

- **Serverless Containers**: No EC2 instance management required
- **Auto Scaling**: Automatic scaling based on demand
- **Load Balancer Integration**: Seamless container registration
- **Health Checks**: Automatic unhealthy container replacement
- **Spot Integration**: Cost optimization with Fargate Spot
- **Circuit Breaker**: Deployment failure protection

## Chaos Engineering Features

- **FIS Experiment Templates**: Predefined failure scenarios
- **Availability Zone Targeting**: Test AZ-specific failures
- **CloudWatch Integration**: Experiment logging and monitoring
- **Controlled Failures**: Safe chaos testing in controlled manner

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Containers run Nginx web server on port 80
- Service maintains 3 tasks across availability zones
- FIS experiments help test application resilience
- Fargate eliminates server management overhead
- All container logs are available in CloudWatch