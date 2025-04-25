aws rds create-db-instance-read-replica \
    --region eu-west-1 \
    --db-instance-identifier demo12-rr-az-a \
    --source-db-instance-identifier demo12-rds-postgresql \
    --db-instance-class db.r5.large \
    --availability-zone eu-west-1a \
    --multi-az 