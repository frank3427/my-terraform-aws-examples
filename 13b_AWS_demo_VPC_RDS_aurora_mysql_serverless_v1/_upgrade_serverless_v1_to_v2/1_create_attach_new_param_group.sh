# ---- Create new parameter group
aws rds create-db-cluster-parameter-group \
    --region eu-west-3 \
    --db-cluster-parameter-group-name aurora-mysql-with-binlogging \
    --description 'Aurora MySQL 5.7 With Binlog Enabled' \
    --db-parameter-group-family aurora-mysql5.7

aws rds modify-db-cluster-parameter-group \
    --region eu-west-3 \
    --db-cluster-parameter-group-name aurora-mysql-with-binlogging \
    --parameters 'ParameterName=binlog_format,ParameterValue=MIXED,ApplyMethod=pending-reboot'

# ---- Attach new parameter group to cluster
aws rds modify-db-cluster \
    --region eu-west-3 \
    --db-cluster-identifier demo13b-aurora-mysql-cluster \
    --db-cluster-parameter-group-name aurora-mysql-with-binlogging \
    --apply-immediately
