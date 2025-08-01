import os
import sys
import argparse
import shutil
import re

# Command line argument parsing------------------------------------------------------
parser = argparse.ArgumentParser()
parser.add_argument("-chip", "--chip", help="Chip infrastructure")
parser.add_argument("--skip-upload", action="store_true", help="Skip the S3 upload step")
parser.add_argument("-aws_access_key", "--aws_access_key", help="AWS Access Key")
parser.add_argument("-aws_secret_key", "--aws_secret_access_key", help="AWS Secret Access Key")
parser.add_argument("-s3", "--s3_bucket", help="AWS S3 Bucket name")
parser.add_argument("-ecr", "--ecr_repo", help="AWS ECR Repository name")
parser.add_argument("-di", "--docker_image", help="Existing Docker Image")
args = parser.parse_args()

chip_infrastructure   = args.chip
aws_access_key        = args.aws_access_key
aws_secret_key        = args.aws_secret_access_key
s3_bucket_name        = args.s3_bucket
ecr_repo_name         = args.ecr_repo
existing_image        = args.docker_image

# Copy appropriate Dockerfile based on chip infrastructure-------------------------
print("Creating new Dockerfile")
if chip_infrastructure == "x86":
    shutil.copyfile("docker_mac_x86/Dockerfile", "./Dockerfile")
else:
    shutil.copyfile("docker_mac_arm64/Dockerfile", "./Dockerfile")

# Add AWS credentials to local environment------------------------------------------
print("Adding AWS credentials to local environment")
os.environ["AWS_ACCESS_KEY"]        = aws_access_key
os.environ["AWS_SECRET_ACCESS_KEY"] = aws_secret_key
os.environ["AWS_REGION"]            = "us-east-1"

# Inject AWS credentials into Dockerfile--------------------------------------------
print("Adding AWS credentials to Dockerfile")
with open("Dockerfile", "r") as docker_f:
    dockerfile = docker_f.read()
dockerfile = re.sub(r"\"YOUR_ACCESS_KEY\"", f"\"{aws_access_key}\"", dockerfile)
dockerfile = re.sub(r"\"YOUR_SECRET_ACCESS_KEY\"", f"\"{aws_secret_key}\"", dockerfile)
with open("Dockerfile", "w") as docker_f:
    docker_f.write(dockerfile)

# Prepare Docker image files--------------------------------------------------------
print("Creating custom set of files for use by docker image")
docker_original_files_dir = "docker_image_files_original"
docker_files_dir          = "docker_image_files"
if os.path.exists(docker_files_dir):
    shutil.rmtree(docker_files_dir)
shutil.copytree(docker_original_files_dir, docker_files_dir)

print("Adding AWS credentials to R environment for docker image")
with open(os.path.join(docker_files_dir, ".Renviron"), "w") as renviron_f:
    renviron_f.writelines([
        f"AWS_ACCESS_KEY=\"{aws_access_key}\"\n",
        f"AWS_SECRET_ACCESS_KEY=\"{aws_secret_key}\"\n"
    ])

# Write out Terraform files---------------------------------------------------------
tf_dir = "terraform_scripts"
print("Creating terraform main.tf file")
with open(os.path.join(tf_dir, "main.tf"), "r") as main_tf_f:
    main_tf = main_tf_f.read()
with open("main.tf", "w") as main_tf_f:
    main_tf_f.write(main_tf)

print("Creating variables.tf file")
with open(os.path.join(tf_dir, "variables.tf"), "r") as tf_var_f:
    variables_tf = tf_var_f.read()
variables_tf = re.sub(r'default = "artis-s3-bucket"', f'default = "{s3_bucket_name}"', variables_tf)
variables_tf = re.sub(r'default = "artis-image"', f'default = "{ecr_repo_name}"', variables_tf)
if chip_infrastructure == "arm64":
    variables_tf = re.sub(r'default = "X86_64"', 'default = "ARM64"', variables_tf)
with open("variables.tf", "w") as tf_var_f:
    tf_var_f.write(variables_tf)

# Update R scripts with S3 bucket name---------------------------------------------
original_docker_dir = docker_original_files_dir
out_docker_dir      = docker_files_dir
r_files = [f for f in os.listdir(original_docker_dir) if re.match(r"run_artis_hs[0-9][0-9]\.R", f)]
for r_file in r_files:
    with open(os.path.join(original_docker_dir, r_file), "r") as f:
        r_contents = f.read()
    r_contents = re.sub(
        r'artis_bucket <- "s3://artis-s3-bucket/"',
        f'artis_bucket <- "s3://{s3_bucket_name}/"',
        r_contents
    )
    print(f"Adding S3 bucket name \"{s3_bucket_name}\" to {os.path.join(out_docker_dir, r_file)}")
    with open(os.path.join(out_docker_dir, r_file), "w") as f:
        f.write(r_contents)

# Update AWS upload/download scripts------------------------------------------------
aws_script_dir = "aws_scripts"
print("Creating S3 upload script")
with open(os.path.join(aws_script_dir, "s3_upload.py"), "r") as s3_upload_f:
    s3_upload = s3_upload_f.read()
s3_upload = re.sub(r's3_bucket_name = "artis-s3-bucket"', f's3_bucket_name = "{s3_bucket_name}"', s3_upload)
with open("s3_upload.py", "w") as s3_upload_f:
    s3_upload_f.write(s3_upload)

print("Creating S3 download script")
with open(os.path.join(aws_script_dir, "s3_download.py"), "r") as s3_download_f:
    s3_download = s3_download_f.read()
s3_download = re.sub(r'artis_bucket_name = "artis-s3-bucket"', f'artis_bucket_name = "{s3_bucket_name}"', s3_download)
with open("s3_download.py", "w") as s3_download_f:
    s3_download_f.write(s3_download)

print("Creating Docker image creation and upload script")
with open(os.path.join(aws_script_dir, "docker_image_create_and_upload.py"), "r") as ecr_f:
    ecr = ecr_f.read()
ecr = re.sub(r'LOCAL_REPOSITORY = "artis-image"', f'LOCAL_REPOSITORY = "{ecr_repo_name}"', ecr)
with open("docker_image_create_and_upload.py", "w") as ecr_f:
    ecr_f.write(ecr)

# Execute infrastructure setup, uploads, and image push----------------------------
try:
    print("Creating AWS infrastructure")
    os.system("terraform init")
    os.system("terraform fmt")
    os.system("terraform validate")
    os.system("terraform apply -auto-approve")

    if args.skip_upload:
        print("Skipping S3 upload step as requested")
    else:
        print("Uploading model input files")
        os.system("python3 s3_upload.py")

    print("Creating docker image and uploading docker image to remote AWS ECR")
    if existing_image is None:
        os.system("python3 docker_image_create_and_upload.py")
    else:
        os.system(f"python3 docker_image_create_and_upload.py -di {existing_image}")

    print("Done!")
except:
    print("Error occured...destroying all AWS resources")
    os.system("terraform destroy -auto-approve")
