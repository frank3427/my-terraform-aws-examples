# Demo 04c: NLB in front of ALB

This Terraform configuration creates a VPC with Network Load Balancer (NLB) in public subnets using Application Load Balancer (ALB) in private subnets as target group.

## Architecture

```
Internet -> NLB (Public Subnets) -> ALB (Private Subnets) -> WebServers (Private Subnets)
```

## Resources Created

- **VPC** with public and private subnets across 2 AZs
- **Internet Gateway** for public subnet connectivity
- **NAT Gateway** for private subnet outbound connectivity
- **Network Load Balancer (NLB)** in public subnets
- **Application Load Balancer (ALB)** in private subnets as NLB target
- **2 Web servers** in private subnets as ALB targets
- **Bastion host** in public subnet for SSH access
- **Security Groups** with appropriate rules
- **SSH Key Pairs** for instances

## Usage

1. Copy `terraform.tfvars.TEMPLATE` to `terraform.tfvars`
2. Modify variables as needed
3. Run:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Testing

After deployment, access the web application via the NLB DNS name provided in the output.

## Cleanup

```bash
terraform destroy
```
