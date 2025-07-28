import os
import base64
import argparse
import docker
import boto3

LOCAL_REPOSITORY = "artis-image"

# If someone only set AWS_ACCESS_KEY / AWS_SECRET_ACCESS_KEY, alias them:
if 'AWS_ACCESS_KEY' in os.environ and 'AWS_ACCESS_KEY_ID' not in os.environ:
    os.environ['AWS_ACCESS_KEY_ID'] = os.environ['AWS_ACCESS_KEY']
if 'AWS_SECRET_ACCESS_KEY' in os.environ and 'AWS_SECRET_ACCESS_KEY' not in os.environ:
    os.environ['AWS_SECRET_ACCESS_KEY'] = os.environ['AWS_SECRET_ACCESS_KEY']

# Command line argument parsing
parser = argparse.ArgumentParser()
parser.add_argument("-di", "--docker_image", help="Existing Docker Image to reuse")
args = parser.parse_args()
existing_image = args.docker_image

# Initialize Docker client
# Note: Docker Desktop (or daemon) must be running
docker_client = docker.from_env()

# List current local Docker images
docker_images = docker_client.images.list()
print("Current Docker Images:")
print(docker_images)

# Build or reuse Docker image
if existing_image:
    docker_image = docker_client.images.get(existing_image)
else:
    docker_fp = "."
    print(f"Starting to build docker image based on Dockerfile at: {docker_fp}")
    docker_image, _ = docker_client.images.build(path=docker_fp, tag=LOCAL_REPOSITORY)
    docker_images = docker_client.images.list()
    print("Current Docker Images:")
    print(docker_images)

# Remove any existing Docker auth config to avoid stale tokens
docker_config = os.path.join(os.environ.get("HOME", "~"), ".docker/config.json")
if os.path.exists(docker_config):
    os.remove(docker_config)

# Determine AWS region
session = boto3.session.Session()
aws_region = session.region_name or os.environ.get("AWS_REGION") or os.environ.get("AWS_DEFAULT_REGION")
if not aws_region:
    raise RuntimeError("AWS region not set in environment or config.")
print(f"Using AWS region: {aws_region}")

# Create ECR client using default credential chain
# This will pick up credentials from ~/.aws/credentials, env vars, or instance role
ecr_client = boto3.client("ecr", region_name=aws_region)

# Fetch ECR auth token and login to AWS ECR
auth_data = ecr_client.get_authorization_token()["authorizationData"][0]
ecr_username, ecr_password = base64.b64decode(auth_data["authorizationToken"]).decode().split(':')
ecr_url = auth_data["proxyEndpoint"].replace("https://", "")
print("Got AWS ECR login token")

docker_client.login(username=ecr_username, password=ecr_password, registry=ecr_url, reauth=True)
print("Docker logged in and authenticated with ECR")

# Tag and push image to AWS ECR
ecr_repo = f"{ecr_url}/{LOCAL_REPOSITORY}"
docker_image.tag(ecr_repo, tag='latest')
print(f"Pushing local image {LOCAL_REPOSITORY} to AWS ECR: {ecr_repo}")

push_log = docker_client.images.push(ecr_repo, tag='latest')
print(push_log)
if "error" in push_log.lower():
    print("Failed to upload docker image to ECR.")
else:
    print("Successfully uploaded docker image to ECR.")
