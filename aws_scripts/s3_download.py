# libraries
import os
import boto3
from datetime import date
import time  # Import the time module

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
#==================================================================================

# Define AWS region
region = "us-east-1"

# Define bucket name
artis_bucket_name = "s3_bucket_name"

# Create an S3 client to interact with AWS S3
s3_client = create_s3_client(region=region)

# Start the timer
start_time = time.time()

# Create a paginator to iterate through S3 bucket objects
paginator = s3_client.get_paginator('list_objects_v2')
# Create a PageIterator from the Paginator
paginator_config = {
    "Bucket": s3_bucket_name,
    "Prefix": "outputs/" # only list objects within the outputs directory
}
page_iterator = paginator.paginate(**paginator_config)

for page in page_iterator:
    # Get contents from page
    page_contents = page["Contents"]
    # Iterate over contents and create directories when needed otherwise download file
    for item in page_contents:
        if item['Key'][-1] == "/":
            print(f"Creating directory {item['Key']}")
            os.makedirs(item['Key'], exist_ok=True)
        else:
            # Ensure the directory exists before downloading the file
            dir_name = os.path.dirname(item['Key'])
            if not os.path.exists(dir_name):
                os.makedirs(dir_name)
            print(f"Downloading file {item['Key']}")
            s3_client.download_file(s3_bucket_name, item['Key'], item['Key'])

# Rename outputs directory with today's date
today = date.today()
print(f"Adding date {today} to outputs directory")
os.rename("outputs", f"outputs_{today}")

# Stop the timer and calculate the elapsed time
end_time = time.time()
elapsed_time = end_time - start_time
print(f"Download completed in {elapsed_time:.2f} seconds.")

print("Done!")
