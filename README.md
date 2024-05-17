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

## Python Installation
1. Create a virtual environment, run terminal command:`python3 -m venv venv`
2. Open virtual environment, run terminal command: `source venv/bin/activate`
3. Install all required python modules, run terminal command: `pip3 install -r requirements.txt`

## Creating AWS Infrastructure with a setup file

Note: the `initial_setup.py` script will create all necessary AWS infrastructure, upload all model inputs to an AWS S3 bucket, and create and upload a docker image based on the ARTIS codebase. It will also submit jobs to the ARTIS HPC.

1. Create AWS infrastructure, upload model inputs and ARTIS docker image, run terminal command: `python3 initial_setup.py -chip [YOUR CHIP INFRASTRUCTURE] -aws_access_key [YOUR AWS KEY] -aws_secret_key [YOUR AWS SECRET KEY] -s3 [S3 bucket name of your choice]  -ecr [Docker image repository name]`
    - Note: This will create the docker image from scratch. If you have an existing docker image you would like to use include the `-di [existing docker image name]` with the command.
        - `python3 initial_setup.py -chip [YOUR CHIP INFRASTRUCTURE] -aws_access_key [YOUR AWS KEY] -aws_secret_key [YOUR AWS SECRET KEY] -s3 [S3 bucket name of your choice]  -ecr [Docker image repository name] -di [existing docker image name]`

**Note:** If terraform states that it created all resources however when you log into the AWS console to confirm cannot see them, they have most likely been created as part of another account. Run `terraform destroy` on the command line. Confirmed you have followed the AWS CLI set up instructions with the correct set of keys (AWS access key and AWS secret access key).


# Download results, Clean up AWS and Docker environments
1. Download "outputs" folder from AWS, run terminal command `python3 s3_download.py`
2. Destroy all AWS resources and dependencies created, run terminal command `terraform destroy`
3. Open Docker Desktop app and delete all containers created
4. Open Docker Desktop app and delete all images created
5. Close python environment, run terminal command: `deactivate`

