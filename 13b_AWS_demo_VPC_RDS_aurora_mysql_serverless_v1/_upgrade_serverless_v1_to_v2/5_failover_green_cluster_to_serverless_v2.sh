# ---- Make the serverless instance a writer (failover)
aws rds failover-db-cluster \
    --region eu-west-3 \
    --db-cluster-identifier demo13b-aurora-mysql-cluster-green-bmjq3c \
    --target-db-instance-identifier demo13b-aurora-mysql-cluster-instance-serverless

sleep 10

aws rds wait db-cluster-available \
    --region eu-west-3 \
    --db-cluster-identifier demo13b-aurora-mysql-cluster-green-bmjq3c
