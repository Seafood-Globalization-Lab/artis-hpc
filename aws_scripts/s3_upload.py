#!/usr/bin/env python3
import os
import sys
import boto3
from botocore.exceptions import ClientError

# ─── CONFIGURATION (from env vars) ──────────────────────────────────────────────

# must export these exact vars beforehand:
aws_key    = os.environ.get("AWS_ACCESS_KEY")
aws_secret = os.environ.get("AWS_SECRET_ACCESS_KEY")
aws_region = os.environ.get("AWS_REGION")

if not (aws_key and aws_secret and aws_region):
    sys.exit(
        "Error: please export AWS_ACCESS_KEY, "
        "AWS_SECRET_ACCESS_KEY, and AWS_REGION before running."
    )

# S3 bucket to mirror into
S3_BUCKET = os.environ.get("ARTIS_S3_BUCKET", "artis-s3-bucket")

# local root directory to mirror
DATA_DIR  = "data_s3_upload"


# ─── HELPERS ─────────────────────────────────────────────────────────────────────

def create_s3_client():
    """Return an S3 client using explicit credentials."""
    return boto3.client(
        "s3",
        region_name=aws_region,
        aws_access_key_id=aws_key,
        aws_secret_access_key=aws_secret
    )

def upload_file(s3, bucket, local_path, key):
    """Upload one file to S3, printing success or failure."""
    try:
        s3.upload_file(local_path, bucket, key)
        print(f"✔ {local_path} → s3://{bucket}/{key}")
    except ClientError as e:
        print(f"✘ {local_path} → s3://{bucket}/{key}: {e}")

# ─── MAIN ────────────────────────────────────────────────────────────────────────

def main():
    s3 = create_s3_client()

    if not os.path.isdir(DATA_DIR):
        sys.exit(f"Error: data directory '{DATA_DIR}' not found.")

    # Walk through all files under DATA_DIR
    for root, _, files in os.walk(DATA_DIR):
        for fname in files:
            local_path = os.path.join(root, fname)
            # strip off leading DATA_DIR/ to build the S3 key
            rel_path = os.path.relpath(local_path, DATA_DIR)
            # normalize to forward slashes for S3
            s3_key   = rel_path.replace(os.sep, "/")
            upload_file(s3, S3_BUCKET, local_path, s3_key)

if __name__ == "__main__":
    main()
