# WARNING - Will delete S3 bucket on AWS. Make sure to download contents
# purpose of this script is to clean out any AWS resources for a fresh model run

#!/bin/bash

# Define the resources to be deleted
LOG_GROUPS=("flowlogs_group" "another_log_group")
S3_BUCKET="artis-s3-bucket"

# Function to delete CloudWatch log groups
delete_log_groups() {
  for log_group in "${LOG_GROUPS[@]}"; do
    echo "Deleting log group: $log_group"
    aws logs delete-log-group --log-group-name "$log_group"
    if [ $? -eq 0 ]; then
      echo "Deleted log group: $log_group"
    else
      echo "Failed to delete log group or log group does not exist: $log_group"
    fi
  done
}


# Function to delete all objects in an S3 bucket and then the bucket itself
delete_s3_bucket() {
  echo "Deleting all objects in S3 bucket: $S3_BUCKET"
  aws s3 rm s3://$S3_BUCKET --recursive
  if [ $? -eq 0 ]; then
    echo "Deleted all objects in S3 bucket: $S3_BUCKET"
    echo "Deleting S3 bucket: $S3_BUCKET"
    aws s3api delete-bucket --bucket $S3_BUCKET
    if [ $? -eq 0 ]; then
      echo "Deleted S3 bucket: $S3_BUCKET"
    else
      echo "Failed to delete S3 bucket: $S3_BUCKET"
    fi
  else
    echo "Failed to delete objects in S3 bucket: $S3_BUCKET"
  fi
}

# Execute the functions
delete_log_groups
delete_iam_roles
delete_s3_bucket

echo "Resource deletion script complete."
