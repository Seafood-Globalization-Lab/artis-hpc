#!/usr/bin/env python3
"""
submit_restart_artis_snet_jobs.py

Loop over the HS_VERSIONS you’ve exported locally (e.g. "02,07,12,17,96") and
submit one AWS Batch job per HS version. Each job will:

 1. Use the existing Docker image in ECR.
 2. Inside the container, source the baked-in helper to pull all ARTIS_model_code/ from S3.
 3. Then source the HS-specific restart script to resume get_snet().

No Docker rebuild or push required.
"""

import os
import sys
import boto3

# --- Configuration ---
AWS_REGION     = os.environ.get("AWS_REGION", "us-east-1")
S3_BUCKET      = "artis-s3-bucket"
JOB_QUEUE      = "artis-job-queue"
JOB_DEFINITION = "artis_job_definition"

# Read HS_VERSIONS from your local environment
hs_env = os.environ.get("HS_VERSIONS")
if not hs_env:
    print("ERROR: HS_VERSIONS not set. Export e.g.: HS_VERSIONS=\"02,07,12,17,96\"")
    sys.exit(1)
hs_versions = hs_env.split(",")

# Initialize AWS Batch client
batch = boto3.client("batch", region_name=AWS_REGION)

for hs in hs_versions:
    # The HS-specific restart script you uploaded to S3
    script_name = f"02-artis-pipeline-restart-snet-hs{hs}.R"

    # Build the shell command to run inside the container:
    # 1) Fetch ALL ARTIS_model_code/ via the baked-in helper
    # 2) Source the HS-specific restart script
    cmd = (
        "R -e \"source('docker_image_artis_pkg_download.R')\" && "
        f"R -e \"source('{script_name}')\""
    )

    # Submit the job, overriding only the container command
    response = batch.submit_job(
        jobName=f"artis-restart-HS{hs}",
        jobQueue=JOB_QUEUE,
        jobDefinition=JOB_DEFINITION,
        containerOverrides={
            "environment": [
                {"name": "AWS_REGION", "value": AWS_REGION}
            ],
            "command": ["bash", "-lc", cmd]
        }
    )

    print(f"Submitted restart job for HS{hs}")
    print(response)

print("All restart jobs submitted.")
