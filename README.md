# ARTIS HPC

This repository outlines the instructions and scripts needed to create the ARTIS High Performance Computer (HPC) on Amazon Web Services (AWS).

## Technologies used
- Terraform
    - This is a set of code scripts that create all the AWS infrastructure needed for the ARTIS HPC
    - Destroy all AWS infrastructure for the ARTIS HPC after the ARTIS model has finished (save on unnecessary costs)
- Docker
    - This is used to create a docker image that our HPC jobs will use to run the ARTIS model code
- Python
    - Through the docker and AWS python (boto3) clients, this will provide code that:
        - Push all model input data to AWS S3
        - Build docker image needed that the AWS Batch jobs will need to run ARTIS model
        - Push docker image to AWS ECR
        - Submit jobs to ARTIS HPC
        - Pull all model outputs data

## Installation
- AWS CLI
- Terraform CLI
- Python
    - Python packages
        - docker
        - boto3

### AWS CLI installation
[Following instructions from AWS](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

The following instructions are for MacOS users:
1. Run terminal command `curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"`
2. Run terminal command `sudo installer -pkg AWSCLIV2.pkg -target /`
3. Confirm AWS CLI has been installed:
    1. Run terminal command `which aws`
    2. Run terminal command `aws --version`

### Terraform CLI installation
To install terraform on MacOS we will be using homebrew. If you do not have homebrew installed on your computer please follow the installation instructions [here](https://brew.sh/), before continuing.

Based on Terraform CLI installation instructions provided [here](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
1. Run terminal command `brew tap hashicorp/tap`
2. Run terminal command `brew install hashicorp/tap/terraform`
3. Run terminal command `brew update`
4. Run terminal command `brew upgrade hashicorp/tap/terraform`

If this has been unsuccessful you might need to install xcode command line tools, try:
- Run terminal command: `sudo xcode-select --install`

## Assumptions:
- An AWS root user was created
- AWS root user has created an admin user group with "AdministratorAccess" permissions.
- AWS root user has created IAM users
- AWS root user has add IAM users to admin group
- AWS IAM users have their AWS AWS_ACCESS_KEY and AWS_SECRET_ACCESS_KEY

## AWS CLI Setup
1. Run terminal command: `export AWS_ACCESS_KEY=[YOUR_AWS_ACCESS_KEY]`
2. Run terminal command: `export AWS_SECRET_ACCESS_KEY=[YOUR_AWS_SECRET_ACCESS_KEY]`
3. Run terminal command `aws configure set aws_access_key_id "[YOUR_AWS_ACCESS_KEY]"`
4. Run terminal command `aws configure set aws_secret_access_key "[YOUR_AWS_SECRET_KEY]"`

## Creating AWS infrastructure using Terraform
1. Download and install terraform providers needed - run terminal command: `terraform init`
2. Format terraform configuration - run terminal command: `terraform fmt`
3. Validate terraform configuration - run terminal command: `terraform validate`
4. Create AWS HPC infrastructure - run terminal command: `terraform apply`
5. Accept these actions when prompted by terraform, type `yes` into terminal. ***Note: this may take a long time since terraform is requesting a variety of AWS resources to be created, and waits until all have been created before returning.***
6. Review AWS infrastructure created via terraform scripts by running terminal command `terraform show`

**Note:** If terraform states that it created all resources however when you log into the AWS console to confirm cannot see them, they have most likely been created as part of another account. Run `terraform destroy` on the command line. Confirmed you have followed the AWS CLI set up instructions with the correct set of keys (AWS access key and AWS secret access key).


## Setting up AWS infrastructure with model resources
Before running our model on AWS we need to send the necessary resources (model input data, docker image) required to run the model.

### Send model inputs to S3 bucket
1. Place model inputs folder into the root project directory
2. Send model inputs to S3 bucket, run terminal command: `python3 s3_upload.py`

### Build and upload local docker image
1. Copy and paste the correct Dockerfile into the root project directory (If your computer runs on an intel chip use docker_mac_x86/Dockerfile, if your computer runs on a apple silicon chip use docker_arm64/Dockerfile)
2. Create and upload docker image, run terminal command `python3 docker_image_create_and_upload.py`


## Running ARTIS model on AWS HPC
1. Send 1 job per HS version to AWS HPC infrastructure, run terminal command `python3 submit_artis_jobs.py`
2. Download "outputs" folder from AWS, run terminal command `python3 s3_download.py`

# Clean up AWS and Docker environments
1. Destroy all AWS resources and dependencies created, run terminal command `terraform destroy`
2. Open Docker Desktop app and delete all containers created
3. Open Docker Desktop app and delete all images created

