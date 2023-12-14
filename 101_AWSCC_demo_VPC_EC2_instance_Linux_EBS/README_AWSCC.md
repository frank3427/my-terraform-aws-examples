## Missing resources in awscc provider

- ec2 instance
- internet gateway attachment
- default route table
- default network acl
- ec2 security group
- cannot add route rule(s) to route table

## Missing data sources in awscc provider

- AMI

## Differences awscc vs aws

- different format to tags
  - aws : tags = { Name = "demo101-rt" }
  - awscc : tags = [{ key = "Name", value = "demo101-rt" }]
