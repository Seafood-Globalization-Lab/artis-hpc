
import os
import json
import base64
import argparse
import docker
import boto3

LOCAL_REPOSITORY = "artis-image"

# Command line argument parsing------------------------------------------------------
parser = argparse.ArgumentParser()

parser.add_argument("-di", "--docker_image", help = "Existing Docker Image")

args = parser.parse_args()

existing_image = args.docker_image

# Create Docker Image===============================================================
# Note: the Docker Desktop app needs to be open before and while running this script
docker_client = docker.from_env()

# Get list of docker images
docker_images = docker_client.images.list()
print("Current Docker Images:")
print(docker_images)

if not (existing_image == None):
    # use existing docker image
    docker_image = docker_client.images.get(existing_image)
else:
    # Create a docker image

    # dockerfile being used
    docker_fp = "."

    print(f"Starting to build docker image based on dockerfile located at: {docker_fp}")
    docker_image = docker_client.images.build(path=docker_fp, tag = LOCAL_REPOSITORY)
    docker_image = docker_image[0]
    docker_images = docker_client.images.list()
    print("Current Docker Images:")
    print(docker_images)

# Upload docker image to AWS ECR=====================================================
# Based on: https://github.com/AlexIoannides/py-docker-aws-example-project/blob/master/deploy_to_aws.py

# Note: AWS ECR repo has already been created by Terraform

# Delete all contents in docker config file if it exists
docker_config_file = os.path.join(os.environ["HOME"], ".docker/config.json")
if os.path.exists(docker_config_file):
    os.remove(docker_config_file)

# Function that reads aws credentials
def read_aws_credentials(filename='.aws_credentials.json'):
    """Read AWS credentials from file.
    
    :param filename: Credentials filename, defaults to '.aws_credentials.json'
    :param filename: str, optional
    :return: Dictionary of AWS credentials.
    :rtype: Dict[str, str]
    """

    try:
        with open(filename) as json_data:
            credentials = json.load(json_data)

        for variable in ('access_key_id', 'secret_access_key', 'region'):
            if variable not in credentials.keys():
                msg = '"{}" cannot be found in {}'.format(variable, filename)
                raise KeyError(msg)
                                
    except FileNotFoundError:
        try:
            credentials = {
                'access_key_id': os.environ['AWS_ACCESS_KEY'],
                'secret_access_key': os.environ['AWS_SECRET_ACCESS_KEY'],
                'region': os.environ['AWS_REGION']
            }
        except KeyError:
            msg = 'no AWS credentials found in file or environment variables'
            raise RuntimeError(msg)

    return credentials

# get AWS credentials
aws_credentials = read_aws_credentials()
access_key_id = aws_credentials['access_key_id']
secret_access_key = aws_credentials['secret_access_key']
aws_region = aws_credentials['region']

print(f"Got AWS credentials {aws_region}")

# get AWS ECR login token
ecr_client = boto3.client(
    'ecr',
    aws_access_key_id=access_key_id, 
    aws_secret_access_key=secret_access_key,
    region_name=aws_region
)

ecr_credentials = (
    ecr_client
        .get_authorization_token()
        ['authorizationData'][0]
)

ecr_username, ecr_password = base64.b64decode(ecr_credentials['authorizationToken']).decode().split(':')
ecr_url = ecr_credentials['proxyEndpoint'].replace("https://", "")
print("Got AWS ECR login token")
# get Docker to login/authenticate with ECR
docker_client.login(
    username=ecr_username,
    password=ecr_password,
    registry=ecr_url,
    reauth=True
)

print("Docker logged in and authenticated with ECR")

# tag image for AWS ECR
ecr_repo_name = f"{ecr_url}/{LOCAL_REPOSITORY}"

docker_image.tag(ecr_repo_name, tag='latest')

print(f"Pushing local docker image artis-image to AWS ECR: {ecr_repo_name}")

# push image to AWS ECR
push_log = docker_client.images.push(ecr_repo_name, tag='latest')

print(push_log)
print("Successfully uploaded docker image to ECR")
