## MISSING resources IN awscc

- ec2 instance
- internet gateway attachment
- default route table
- default network acl
- ec2 security group
- cannot add route rule(s) to route table

## MISSING data sources IN awscc

- AMI

## DIFFERENCES

- different format to tags
  aws : tags = { Name = "demo101-rt" }
  awscc : tags = [{ key = "Name", value = "demo101-rt" }]
