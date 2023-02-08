AWS PrivateLink demo:
AWS PrivateLink demo:

- VPC (provider) with 1 private subnet and 1 public subnet
  - Network LB in public subnet (listener on port 80)
  - 2 EC2 instances for Web servers in private subnets (targets of LB)
  - 1 EC2 instance in public subnet (bastion)
  - 1 endpoint service using the network LB
- VPC (consumer) with 1 public subnet
  - 1 EC2 instance
  - 1 endpoint to endpoint service in provider VPC
