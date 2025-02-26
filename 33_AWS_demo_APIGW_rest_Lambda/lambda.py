import json
import os


# ---- lambda handler
def lambda_handler(event, context):
    print("DEBUG: Received event: " + json.dumps(event, indent=4))
    try:
        name = event["queryStringParameters"]["name"]
    except:
        name = "no-name"

    body     = { "message": f"hello world {name}" }
    response = { "statusCode": 200, "body": json.dumps(body) }

    return response
