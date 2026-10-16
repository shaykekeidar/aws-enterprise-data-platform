
import json
import logging
import os
import tempfile
from pathlib import Path
from urllib.parse import unquote_plus

import boto3

from validator import validate_csv


# AWS clients
s3 = boto3.client("s3")

# Structured logging to CloudWatch
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


# S3 prefixes - configured via Lambda environment variables
INCOMING_PREFIX = os.environ["INCOMING_PREFIX"]
RAW_PREFIX = os.environ["RAW_PREFIX"]
QUARANTINE_PREFIX = os.environ["QUARANTINE_PREFIX"]

# Schema bundled with Lambda
SCHEMA_PATH = Path(__file__).parent / "schema.json"


def log_result(
    status,
    result_code,
    source,
    destination=None,
    errors=None,
    request_id=None
):
    """Write a structured JSON log and return the record."""

    log_entry = {
        "event": "csv_validation",
        "status": status,
        "result_code": result_code,
        "source": source,
        "destination": destination,
        "errors": errors or [],
        "request_id": request_id
    }

    if status == "ERROR":
        logger.error(json.dumps(log_entry))
    else:
        logger.info(json.dumps(log_entry))

    return log_entry


def lambda_handler(event, context):
    """Validate and route CSV files from the S3 incoming prefix."""

    results = []
    request_id = getattr(context, "aws_request_id", None)

    for record in event.get("Records", []):

        # Ignore events unrelated to new S3 objects
        if not record.get("eventName", "").startswith("ObjectCreated:"):
            continue

        bucket = record["s3"]["bucket"]["name"]
        key = unquote_plus(record["s3"]["object"]["key"])
        version_id = record["s3"]["object"].get("versionId")

        # Ignore objects outside the configured incoming prefix
        if not key.startswith(INCOMING_PREFIX) or key.endswith("/"):
            continue

        try:
            logger.info(json.dumps({
                "event": "csv_processing_started",
                "bucket": bucket,
                "source": key,
                "request_id": request_id
            }))

            # Preserve the relative path inside the office prefix
            relative_path = key[len(INCOMING_PREFIX):]

            copy_source = {
                "Bucket": bucket,
                "Key": key
            }

            if version_id:
                copy_source["VersionId"] = version_id

            # Download CSV to Lambda temporary storage
            with tempfile.TemporaryDirectory() as temp_dir:
                local_file = Path(temp_dir) / "uploaded.csv"

                download_args = {
                    "Bucket": bucket,
                    "Key": key
                }

                if version_id:
                    download_args["VersionId"] = version_id

                response = s3.get_object(**download_args)

                with open(local_file, "wb") as file:
                    for chunk in response["Body"].iter_chunks(
                        chunk_size=1024 * 1024
                    ):
                        if chunk:
                            file.write(chunk)

                # Validate using existing validator.py
                try:
                    valid, errors = validate_csv(
                        local_file,
                        SCHEMA_PATH
                    )

                except UnicodeError as exc:
                    valid = False
                    errors = [
                        f"Invalid CSV encoding: {exc}"
                    ]

            # Choose destination based on validation result
            if valid:
                destination_key = RAW_PREFIX + relative_path
                status = "VALID"
                result_code = 0
            else:
                destination_key = QUARANTINE_PREFIX + relative_path
                status = "INVALID"
                result_code = 1

            # Copy validated/rejected file to its destination
            s3.copy_object(
                Bucket=bucket,
                Key=destination_key,
                CopySource=copy_source
            )

            # Remove incoming object only after a successful copy
            # For a versioned bucket, this creates a delete marker.
            s3.delete_object(
                Bucket=bucket,
                Key=key
            )

            # Structured result log
            result = log_result(
                status=status,
                result_code=result_code,
                source=key,
                destination=destination_key,
                errors=errors,
                request_id=request_id
            )

            results.append(result)

        except Exception as exc:
            log_result(
                status="ERROR",
                result_code=2,
                source=key,
                errors=[str(exc)],
                request_id=request_id
            )

            # Important: unexpected processing failures should
            # cause Lambda to fail, allowing retry handling.
            raise

    return {
        "statusCode": 200,
        "body": json.dumps(results)
    }