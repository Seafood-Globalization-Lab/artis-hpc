
import os
import docker
import boto3

# Create Docker Image===============================================================
# Note: the Docker Desktop app needs to be open before and while running this script
client = docker.from_env()

# Get list of docker images
docker_images = client.images.list()
print("Current Docker Images:")
print(docker_images)

# dockerfile being used
docker_fp = "."

# Create a docker image
print(f"Starting to build docker image based on dockerfile located at: {docker_fp}")
docker_image = client.images.build(path=docker_fp, tag = "artis-image")
docker_images = client.images.list()
print("Current Docker Images:")
print(docker_images)

# Upload docker image to AWS ECR=====================================================
# Based on: https://github.com/AlexIoannides/py-docker-aws-example-project/blob/master/deploy_to_aws.py

# Note: AWS ECR repo has already been created by Terraform