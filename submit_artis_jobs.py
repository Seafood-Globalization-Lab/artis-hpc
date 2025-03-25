
import os
import boto3

batch_client = boto3.client("batch",
                            region_name=os.environ["AWS_REGION"])
     
# Pull HS versions from environmental variable set in run instructions README.                             
try:
    hs_versions = os.environ["HS_VERSIONS"].split(",")
except KeyError:
    print("HS_VERSIONS environment variable not set. Please export it before running this script.")
    sys.exit(1)

# 
for hs_version in hs_versions:
    response = batch_client.submit_job(
        jobName = f"artis-HS{hs_version}",
        jobQueue = "artis-job-queue",
        jobDefinition = "artis_job_definition",
        containerOverrides = {
            "command": ["bash", f"job_shell_scripts/job_hs{hs_version}.sh"]
        }
    )

    print(f"HS{hs_version} job submitted")
    print(response)

print("Done submitting jobs to AWS Batch")


