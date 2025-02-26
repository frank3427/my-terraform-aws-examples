import json
import os


# ---- lambda handler
def lambda_handler(event, context):
    # print("DEBUG: Received event: " + json.dumps(event, indent=4))

    response = { "message": "hello world"}

    return response
