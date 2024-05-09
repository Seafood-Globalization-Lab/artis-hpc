
# Specifies:
# which version of terraform to use
# version of providers (AWS) to pull from Terraform registry
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.48.0"
    }
  }

  required_version = ">=1.8.3"
}

# Setting region for all AWS infrastructure
provider "aws" {
  region = "us-east-1"
}

# Create S3 bucket where we will store model inputs and outputs
resource "aws_s3_bucket" "artis-s3" {
  bucket = "artis-s3-example-tf"
}


# Create Elastic Container Registry (ECR) (repo to store docker images)
# Note: this ECR repository will be created in your private registry

resource "aws_ecr_repository" "artis-hs-ecr" {
  name                 = "artis-hs-run-example-tf"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
}

# Create AWS cloudformation stack
# This will be the network under which our compute engine will run all jobs
# and connect with the rest of our AWS resources (s3 and ECR)
# Network created will use the "VPC-Large-Scale.yaml" as a base structure
resource "aws_cloudformation_stack" "network" {
  name          = "artis-network-stack"
  template_body = file("${path.root}/VPC-Large-Scale.yaml")
  parameters = {
    AvailabilityZones      = "us-east-1a,us-east-1b,us-east-1c,us-east-1d,us-east-1e,us-east-1f"
    NumberOfAZs            = 6
    CreatePublicSubnet     = true
    PublicSubnetAZ         = "us-east-1a"
    CreateS3Endpoint       = true
    CreateDynamoDBEndpoint = true
  }
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_AUTO_EXPAND"]
}

