# ---- Remove the provisioned instance
aws rds delete-db-instance \
    --region eu-west-3 \
    --db-instance-identifier demo13b-aurora-mysql-cluster-instance-1-green-puhjrs
