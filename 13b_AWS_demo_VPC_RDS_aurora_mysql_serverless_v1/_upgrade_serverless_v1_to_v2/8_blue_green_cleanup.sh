aws rds delete-db-instance \
    --region eu-west-3 \
    --db-instance-identifier demo13b-aurora-mysql-cluster-instance-1
 
aws rds delete-db-cluster \
    --region eu-west-3 \
    --db-cluster-identifier demo13b-aurora-mysql-cluster-old1 \
    --final-db-snapshot-identifier demo13b-aurora-mysql-cluster-old1-snap

BGDID=`aws rds describe-blue-green-deployments | jq -r ".BlueGreenDeployments[].BlueGreenDeploymentIdentifier"`

aws rds delete-blue-green-deployment \
    --region eu-west-3 \
    --blue-green-deployment-identifier $BGDID