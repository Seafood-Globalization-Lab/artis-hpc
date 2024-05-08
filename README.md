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
