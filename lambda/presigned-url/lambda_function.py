import json
import os
import uuid
import boto3

s3 = boto3.client("s3")


def lambda_handler(event, context):
    claims = (
        event.get("requestContext", {})
             .get("authorizer", {})
             .get("jwt", {})
             .get("claims", {})
    )

    # Authorize Office A users
    if claims.get("office_id") != "office-a":
        return {
            "statusCode": 403,
            "body": json.dumps({"error": "Forbidden"})
        }

    bucket = os.environ["CENTRAL_DATA_LAKE_BUCKET"]
    key = f"incoming/office-a/{uuid.uuid4()}.csv"

    # Generate short-lived presigned PUT URL
    upload_url = s3.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": bucket,
            "Key": key,
            "ContentType": "text/csv"
        },
        ExpiresIn=300,
        HttpMethod="PUT"
    )

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "upload_url": upload_url,
            "object_key": key,
            "expires_in": 300
        })
    }