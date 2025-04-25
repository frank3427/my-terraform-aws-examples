aws rds create-blue-green-deployment \
    --region eu-west-3 \
    --source arn:aws:rds:eu-west-3:147785346668:cluster:demo13b-aurora-mysql-cluster \
    --blue-green-deployment-name aurora-mysql-serverless-green \
    --target-engine-version 8.0.mysql_aurora.3.05.2 \
    --target-db-cluster-parameter-group-name default.aurora-mysql8.0

sleep 10

aws rds wait db-cluster-available \
    --region eu-west-3 \
    --db-cluster-identifier demo13b-aurora-mysql-cluster-green-bmjq3c

aws rds wait db-instance-available \
    --region eu-west-3 \
    --db-instance-identifier demo13b-aurora-mysql-cluster-instance-1-green-puhjrs
