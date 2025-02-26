# ---- Create the Scaling configuration for serverless v2
aws rds modify-db-cluster \
    --region eu-west-3 \
    --db-cluster-identifier demo13b-aurora-mysql-cluster-green-bmjq3c \
    --serverless-v2-scaling-configuration MinCapacity=1,MaxCapacity=4

# ---- Add serverless instance to the RDS cluster
aws rds create-db-instance \
    --region eu-west-3 \
    --db-instance-identifier demo13b-aurora-mysql-cluster-instance-serverless \
    --db-instance-class db.serverless \
    --engine aurora-mysql \
    --db-cluster-identifier demo13b-aurora-mysql-cluster-green-bmjq3c 

sleep 10

aws rds wait db-instance-available \
    --region eu-west-3 \
    --db-instance-identifier demo13b-aurora-mysql-cluster-instance-serverless