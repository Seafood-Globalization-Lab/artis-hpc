
# libraries
import os
import boto3

# Functions=======================================================================

# Create an S3 client based on region
def create_s3_client(region=None):
    s3_client = None
    if region is None:
        # Create an S3 bucket client in the default region in the aws config file
        s3_client = boto3.client("s3")
    else:
        # Create an S3 bucket client in a specific AWS region
        s3_client = boto3.client("s3", region_name=region)
    return s3_client

# List all buckets available to user
def list_s3_buckets(s3_client=None):
    s3_buckets = []

    response = s3_client.list_buckets()
    s3_buckets = [bucket["Name"] for bucket in response["Buckets"]]
    return s3_buckets

# Create an S3 bucket
# taken from: https://boto3.amazonaws.com/v1/documentation/api/latest/guide/s3-example-creating-buckets.html
def create_s3_bucket(s3_client, bucket_name, region=None):

    # Create S3 Bucket
    try:
        if region is None:
            s3_client.create_bucket(Bucket=bucket_name)
        else:
            location = {"LocationConstraint": region}
            s3_client.create_bucket(Bucket=bucket_name,
                                    CreateBucketConfiguration=location)
    except ClientError as e:
        print(e)
        return False
    
    return True

# Upload file to S3 bucket
# Based on: https://boto3.amazonaws.com/v1/documentation/api/latest/guide/s3-uploading-files.html
def upload_file(s3_client=None, bucket_name=None, file_name=None, object_name=None):

    if not object_name:
        object_name = file_name
    
    try:
        response = s3_client.upload_file(
            file_name,
            bucket_name,
            object_name
        )
    except ClientError as e:
        return False
    return True


#==================================================================================

# Define AWS region
region = "us-east-1"
# Create an S3 client to interact with AWS S3
s3_client = create_s3_client(region=region)
# Define bucket name
s3_bucket_name = "artis-s3-bucket"

# Note: S3 bucket will have already been created through Terraform scripts

# Upload all model inputs data to S3 bucket
data_s3_upload_dir = "data_s3_upload"
model_inputs_dir = "model_inputs"
datadir = os.path.join(data_s3_upload_dir, model_inputs_dir)
print(datadir)
datadir_contents = os.listdir(datadir)
# Only get files within data directory
data_files = [f for f in datadir_contents if os.path.isfile(os.path.join(datadir, f))]

# AWS data directory
aws_model_inputs_fp = model_inputs_dir

# Upload all data files from data directory to S3 object
for data_file in data_files:
    file_fp = os.path.join(datadir, data_file)
    aws_fp = os.path.join(aws_model_inputs_fp, data_file)
    # Note: the files will follow the same file and directory structure that the local data directory has.
    response = upload_file(
        s3_client= s3_client,
        bucket_name = s3_bucket_name,
        file_name = file_fp,
        object_name = aws_fp
    )

    if response:
        print(f"Successful upload {file_fp} to {aws_fp}")
    else:
        print(f"Error uploading {file_fp} to {aws_fp}")


# Upload all ARTIS model code files

# Uploading base set of model running files
artis_r_dir = os.path.join(data_s3_upload_dir, "ARTIS_model_code")
artis_r_contents = os.listdir(artis_r_dir)
base_pkg_files = [f for f in artis_r_contents if os.path.isfile(os.path.join(artis_r_dir, f))]

aws_r_code_dir = "ARTIS_model_code"

for base_f in base_pkg_files:
    base_f_fp = os.path.join(artis_r_dir, base_f)
    aws_f_fp = os.path.join(aws_r_code_dir, base_f)
    response = upload_file(
        s3_client = s3_client,
        bucket_name = s3_bucket_name,
        file_name = base_f_fp,
        object_name = aws_f_fp
    )

    if response:
        print(f"Successful upload {base_f_fp} to {aws_f_fp}")
    else:
        print(f"Error uploading {base_f_fp} to {aws_f_fp}")

# Uploading all ARTIS R package files
artis_pkg_dir = os.path.join(artis_r_dir, "R")
artis_pkg_contents = os.listdir(artis_pkg_dir)
artis_pkg_files = [f for f in artis_pkg_contents if os.path.isfile(os.path.join(artis_pkg_dir, f))]

aws_pkg_dir = os.path.join(aws_r_code_dir, "R")

for pkg_f in artis_pkg_files:

    pkg_f_fp = os.path.join(artis_pkg_dir, pkg_f)
    aws_pkg_f_fp = os.path.join(aws_pkg_dir, pkg_f)

    response = upload_file(
        s3_client = s3_client,
        bucket_name = s3_bucket_name,
        file_name = pkg_f_fp,
        object_name = aws_pkg_f_fp
    )

    if response:
        print(f"Successful upload {pkg_f_fp} to {aws_pkg_f_fp}")
    else:
        print(f"Error uploading {pkg_f_fp} to {aws_pkg_f_fp}")
