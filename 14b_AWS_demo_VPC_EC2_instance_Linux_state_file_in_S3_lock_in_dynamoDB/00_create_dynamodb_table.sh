#!/bin/bash

TMP_FILE=tmp.json

cat > $TMP_FILE <<EOF
{
    "TableName": "TerraformLock",
    "KeySchema": [
      { "AttributeName": "LockID", "KeyType": "HASH" }
    ],
    "AttributeDefinitions": [
      { "AttributeName": "LockID", "AttributeType": "S" }
    ],
    "ProvisionedThroughput": {
      "ReadCapacityUnits": 5,
      "WriteCapacityUnits": 5
    }
}
EOF

aws dynamodb create-table \
    --cli-input-json file://$TMP_FILE \
    --region eu-west-3
