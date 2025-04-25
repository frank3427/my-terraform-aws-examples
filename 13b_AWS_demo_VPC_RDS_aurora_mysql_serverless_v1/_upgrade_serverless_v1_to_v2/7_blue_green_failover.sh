BGDID=`aws rds describe-blue-green-deployments | jq -r ".BlueGreenDeployments[].BlueGreenDeploymentIdentifier"`

aws rds switchover-blue-green-deployment \
    --region eu-west-3 \
    --blue-green-deployment-identifier $BGDID \
    --switchover-timeout 120
 
# aws rds wait db-cluster-available \
#     --region eu-west-3 \
#     --db-cluster-identifier demo13b-aurora-mysql-cluster

# aws rds wait db-instance-available \
#     --region eu-west-3 \
#     --db-instance-identifier aurora-mysql-serverless-a