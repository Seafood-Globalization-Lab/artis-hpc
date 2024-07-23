
import os
import boto3

batch_client = boto3.client("batch",
                            region_name=os.environ["AWS_REGION"])

response = batch_client.submit_job(
        jobName = f"artis-combine-tables",
        jobQueue = "artis-job-queue",
        jobDefinition = "artis_job_definition",
        containerOverrides = {
            "command": ["bash", f"job_shell_scripts/job_combine_tables.sh"]
        }
    )

print("Done submitting ARTIS table combination job")


