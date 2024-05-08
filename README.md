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
