REGION="eu-north-1"
aws ec2 describe-instance-types  \
	--region $REGION  \
	--filters Name=network-info.efa-supported,Values=true  \
	--query "InstanceTypes[*].[InstanceType]"  --output text | sort
