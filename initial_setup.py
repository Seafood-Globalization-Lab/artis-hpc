
import os
import sys
import argparse
import shutil
import re

# Command line argument parsing------------------------------------------------------
parser = argparse.ArgumentParser()

parser.add_argument("-chip", "--chip", help = "Chip infrastructure")
parser.add_argument("-aws_access_key", "--aws_access_key", help = "AWS Access Key")
parser.add_argument("-aws_secret_key", "--aws_secret_access_key", help = "AWS Secret Access Key")
parser.add_argument("-s3", "--s3_bucket", help = "AWS S3 Bucket name")
parser.add_argument("-ecr", "--ecr_repo", help = "AWS ECR Repository name")

args = parser.parse_args()

chip_infrastructure = args.chip
aws_access_key = args.aws_access_key
aws_secret_key = args.aws_secret_access_key
s3_bucket_name = args.s3_bucket
ecr_repo_name = args.ecr_repo

print(args)

# Copy appropriate dockerfile to project root directory based on chip infrastructure---------------
print("Creating new Dockerfile")
if args.chip == "x86":
    shutil.copyfile("docker_mac_x86/Dockerfile", "./Dockerfile")
else:
    shutil.copyfile("docker_mac_arm64/Dockerfile", "./Dockerfile")

# Add AWS credentials to all relevant places--------------------------------------------------------
print("Adding AWS credentials to local environment")
# Adding credentials to local environment
os.environ["AWS_ACCESS_KEY"] = aws_access_key
os.environ["AWS_SECRET_ACCESS_KEY"] = aws_secret_key

# Add AWS credentials to Dockerfile for docker image
print("Adding AWS credentials to Dockerfile")
docker_f = open("Dockerfile", "r")
dockerfile = docker_f.read()
docker_f.close()

dockerfile = re.sub("\"YOUR_ACCESS_KEY\"", f"\"{aws_access_key}\"", dockerfile)
dockerfile = re.sub("\"YOUR_SECRET_ACCESS_KEY\"", f"\"{aws_secret_key}\"", dockerfile)

docker_f = open("Dockerfile", "w")
docker_f.write(dockerfile)
docker_f.close()

# Add AWS credentials to R environment for docker image
print("Adding AWS credentials to R environment for docker image")
renviron_f = open("docker_image_files/.Renviron", "w")
renviron_f.writelines([
    f"AWS_ACCESS_KEY=\"{aws_access_key}\"",
    f"AWS_SECRET_ACCESS_KEY=\"{aws_secret_key}\""
])
renviron_f.close()

# writing out original main tf file to project root directory
tf_dir = "terraform_scripts"
main_tf_f = open(os.path.join(tf_dir, "main.tf"), "r")
main_tf = main_tf_f.read()
main_tf_f.close()

print("Creating terraform main.tf file")
main_tf_f = open("main.tf", "w")
main_tf_f.write(main_tf)
main_tf_f.close()

# Adding S3 and ECR names to all appropriate files

# Adding S3 and ECR to terraform files
print("Creating variables.tf file")
tf_var_f = open(os.path.join(tf_dir, "variables.tf"), "r")
variables_tf = tf_var_f.read()
tf_var_f.close()

variables_tf = re.sub("default = \"artis-s3-bucket\"", f"default = \"{s3_bucket_name}\"", variables_tf)
variables_tf = re.sub("default = \"artis-image\"", f"default = \"{ecr_repo_name}\"", variables_tf)

tf_var_f = open("variables.tf", "w")
tf_var_f.write(variables_tf)
tf_var_f.close()

# Adding S3 bucket name to all R files
original_docker_dir = "docker_image_files_original"
out_docker_dir = "docker_image_files"

r_files = os.listdir(original_docker_dir)
print(r_files)
r_files = [f for f in r_files if re.match("run_artis_hs[0-9][0-9]\\.R", f)]
print(r_files)

for r_file in r_files:
    f = open(os.path.join(original_docker_dir, r_file), "r")
    r_contents = f.read()
    f.close()

    
    r_contents = re.sub("artis_bucket <- \"s3://artis-s3-bucket/\"",
                        f"artis_bucket <- \"s3://{s3_bucket_name}/\"",
                        r_contents)
    
    print(f"Adding S3 bucket name \"{s3_bucket_name}\" to {os.path.join(out_docker_dir, r_file)}")
    f = open(os.path.join(out_docker_dir, r_file), "w")
    f.write(r_contents)
    f.close()

print("Done")
