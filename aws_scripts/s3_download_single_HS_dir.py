# download s3 outputs/snet by a single HS version "folder"

#!/usr/bin/env python3
# s3_download.py
import os
import sys
import time
from datetime import date
import boto3

def create_s3_client():
    # Region from env or default
    region = os.environ.get("ARTIS_S3_REGION") \
          or os.environ.get("AWS_REGION") \
          or os.environ.get("AWS_DEFAULT_REGION") \
          or "us-east-1"
    return boto3.client("s3", region_name=region)

def main():
    if len(sys.argv) != 2:
        print("Usage: python s3_download.py <HSxx>   e.g., python s3_download.py HS12")
        sys.exit(1)

    hs_folder = sys.argv[1].strip("/ ")

    bucket     = os.environ.get("ARTIS_S3_BUCKET", "artis-s3-bucket")
    root_prefix = os.environ.get("ARTIS_S3_ROOT_PREFIX", "outputs/snet").strip("/ ")
    s3_prefix  = f"{root_prefix}/{hs_folder}/"  # e.g., outputs/snet/HS12/
    dest_root  = os.environ.get("ARTIS_DEST_ROOT", s3_prefix.rstrip("/"))
    no_rename  = os.environ.get("ARTIS_NO_RENAME", "0") == "1"

    s3 = create_s3_client()

    print(f"Bucket: s3://{bucket}")
    print(f"S3 prefix: {s3_prefix}")
    print(f"Local dest root: {dest_root}")

    os.makedirs(dest_root, exist_ok=True)

    start = time.time()
    paginator = s3.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=bucket, Prefix=s3_prefix)

    downloaded = 0
    for page in pages:
        contents = page.get("Contents", [])
        if not contents:
            continue
        for obj in contents:
            key = obj["Key"]
            if key.endswith("/"):
                continue  # skip folder placeholders

            rel = os.path.relpath(key, s3_prefix)
            local_path = os.path.join(dest_root, rel)
            os.makedirs(os.path.dirname(local_path), exist_ok=True)

            print(f"Downloading s3://{bucket}/{key} -> {local_path}")
            s3.download_file(bucket, key, local_path)
            downloaded += 1

    if downloaded == 0:
        print(f"No objects found under s3://{bucket}/{s3_prefix}")
    else:
        print(f"Downloaded {downloaded} file(s).")
        if not no_rename:
            parent = os.path.dirname(dest_root.rstrip("/"))
            base   = os.path.basename(dest_root.rstrip("/"))
            new_dest = os.path.join(parent, f"{base}_{date.today()}")
            print(f"Renaming {dest_root} -> {new_dest}")
            os.rename(dest_root, new_dest)

    print(f"Completed in {time.time() - start:.2f} seconds.")

if __name__ == "__main__":
    main()
