aws rds modify-db-cluster \
    --region eu-west-3 \
    --db-cluster-identifier demo13b-aurora-mysql-cluster \
    --engine-mode provisioned \
    --allow-engine-mode-change \
    --db-cluster-instance-class db.r5.xlarge \
    --apply-immediately

aws rds wait db-instance-available \
    --region eu-west-3 \
    --db-instance-identifier demo13b-aurora-mysql-cluster-instance-1

aws rds wait db-cluster-available \
    --region eu-west-3 \
    --db-cluster-identifier demo13b-aurora-mysql-cluster