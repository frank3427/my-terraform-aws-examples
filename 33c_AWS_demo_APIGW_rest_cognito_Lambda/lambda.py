import json
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# ---- lambda handler
def lambda_handler(event, context):
    logger.info("Received event: " + json.dumps(event, indent=4))

    response_body = {
        "message": "Hello World from demo33c"
    }
    response = { 
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response_body)
    }

    logger.info("Response: " + json.dumps(response, indent=4))

    return response
