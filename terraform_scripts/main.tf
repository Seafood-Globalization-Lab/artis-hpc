
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
  bucket        = var.s3_bucket_name
  force_destroy = true
}


# Create Elastic Container Registry (ECR) (repo to store docker images)
# Note: this ECR repository will be created in your private registry
resource "aws_ecr_repository" "artis_hs_ecr" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = false
  }
}


# Create an AWS cloudformation stack from scratch based--------------------------------
# Here we will translate the whole yaml template into terraform instructions for reference later
# This means we will build each individual resource ourselves

# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr0
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "artis-vpc"
  }
}

# Create Log group for Flow Logs
resource "aws_cloudwatch_log_group" "flowlogs_group" {
  name              = "flowlogs_group"
  retention_in_days = 7
}

# Create a IAM policy for VPC Flow Logs
resource "aws_iam_role_policy" "flowlogs_policy" {
  name = "flowlogs_policy"
  role = aws_iam_role.flowlogs_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = aws_cloudwatch_log_group.flowlogs_group.arn
    }]
  })
}

# Create IAM role for VPC flow logs
resource "aws_iam_role" "flowlogs_role" {
  name = "flowlogs_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

# Create flow log for VPC
resource "aws_flow_log" "flowlogs_vpc" {
  iam_role_arn    = aws_iam_role.flowlogs_role.arn
  vpc_id          = aws_vpc.vpc.id
  log_destination = aws_cloudwatch_log_group.flowlogs_group.arn
  traffic_type    = "ALL"
}

# Create VpcCidrBlock1
resource "aws_vpc_ipv4_cidr_block_association" "vpc_cidrblock1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.cidr1
  depends_on = [
    aws_vpc.vpc
  ]
}

# Create VpcCidrBlock2
resource "aws_vpc_ipv4_cidr_block_association" "vpc_cidrblock2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.cidr2
  depends_on = [
    aws_vpc.vpc
  ]
}

# Create VpcCidrBlock3
resource "aws_vpc_ipv4_cidr_block_association" "vpc_cidrblock3" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.cidr3
  depends_on = [
    aws_vpc.vpc
  ]
}

# Create internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "internet_gateway"
  }
}
/*
# Create Gateway to Internet
resource "aws_internet_gateway_attachment" "internet_gateway_attachment" {
  vpc_id              = aws_vpc.vpc.id
  internet_gateway_id = aws_internet_gateway.internet_gateway.id
}
*/
# Create Elastic IP
resource "aws_eip" "elastic_ip" {
  domain = "vpc"
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(var.cidr0, 1, 0)
  depends_on = [
    aws_vpc.vpc
  ]
  tags = {
    Name = "artis-vpc Public Subnet"
  }
}

# Create a NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public_subnet.id
}

# Create security groups for instances launched in teh VPC by AWS Batch
resource "aws_security_group" "vpc_security_group" {
  name   = "vpc_security_group"
  vpc_id = aws_vpc.vpc.id
  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create private subnet for each availability zone
resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc_ipv4_cidr_block_association.vpc_cidrblock1.vpc_id
  cidr_block        = cidrsubnets(var.cidr1, 1, 1)[0]
  availability_zone = "us-east-1a"
  depends_on = [
    aws_vpc_ipv4_cidr_block_association.vpc_cidrblock1
  ]
}

resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc_ipv4_cidr_block_association.vpc_cidrblock1.vpc_id
  cidr_block        = cidrsubnets(var.cidr1, 1, 1)[1]
  availability_zone = "us-east-1b"
  depends_on = [
    aws_vpc_ipv4_cidr_block_association.vpc_cidrblock1
  ]
}

resource "aws_subnet" "private_subnet3" {
  vpc_id            = aws_vpc_ipv4_cidr_block_association.vpc_cidrblock2.vpc_id
  cidr_block        = cidrsubnets(var.cidr2, 1, 1)[0]
  availability_zone = "us-east-1c"
  depends_on = [
    aws_vpc_ipv4_cidr_block_association.vpc_cidrblock2
  ]
}

resource "aws_subnet" "private_subnet4" {
  vpc_id            = aws_vpc_ipv4_cidr_block_association.vpc_cidrblock2.vpc_id
  cidr_block        = cidrsubnets(var.cidr2, 1, 1)[1]
  availability_zone = "us-east-1d"
  depends_on = [
    aws_vpc_ipv4_cidr_block_association.vpc_cidrblock2
  ]
}

resource "aws_subnet" "private_subnet5" {
  vpc_id            = aws_vpc_ipv4_cidr_block_association.vpc_cidrblock3.vpc_id
  cidr_block        = cidrsubnets(var.cidr3, 1, 1)[0]
  availability_zone = "us-east-1e"
  depends_on = [
    aws_vpc_ipv4_cidr_block_association.vpc_cidrblock3
  ]
}

resource "aws_subnet" "private_subnet6" {
  vpc_id            = aws_vpc_ipv4_cidr_block_association.vpc_cidrblock3.vpc_id
  cidr_block        = cidrsubnets(var.cidr3, 1, 1)[1]
  availability_zone = "us-east-1f"
  depends_on = [
    aws_vpc_ipv4_cidr_block_association.vpc_cidrblock3
  ]
}

# Create a Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc
  ]
}

# Create Public Route
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

# Create Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc
  ]
}

# Create Private route to internet
resource "aws_route" "private_route_to_internet" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
  depends_on = [
    aws_vpc.vpc,
    aws_nat_gateway.nat_gateway
  ]
}

# Associate the public route table to the public subnet
resource "aws_route_table_association" "public_subnet_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
  depends_on = [
    aws_subnet.public_subnet,
    aws_route_table.public_route_table
  ]
}

# Associate the private route table each private subnet
resource "aws_route_table_association" "private_subnet1_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet2_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet3_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet3.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet4_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet4.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet5_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet5.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet6_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet6.id
  route_table_id = aws_route_table.private_route_table.id
}

# Create an S3 endpoint
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id          = aws_vpc.vpc.id
  service_name    = var.s3_service_name
  route_table_ids = [
    aws_route_table.private_route_table.id,
    aws_route_table.public_route_table.id
  ]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "*"
      Resource  = "*"
    }]
  })
}

# Create an ECR endpoint
resource "aws_vpc_endpoint" "ecr_api_endpoint" {
  vpc_id            = aws_vpc.vpc.id
  vpc_endpoint_type = "Interface"
  service_name      = var.ecr_api_service_name
  #route_table_ids = [aws_route_table.private_route_table.id]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "*"
      Resource  = "*"
    }]
  })
}

resource "aws_vpc_endpoint" "ecr_dkr_endpoint" {
  vpc_id            = aws_vpc.vpc.id
  vpc_endpoint_type = "Interface"
  service_name      = var.ecr_dkr_service_name
  #route_table_ids = [aws_route_table.private_route_table.id]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "*"
      Resource  = "*"
    }]
  })
}

# Create a DynamoDB endpoint
resource "aws_vpc_endpoint" "dynamodb_endpoint" {
  vpc_id          = aws_vpc.vpc.id
  service_name    = var.dynamodb_service_name
  route_table_ids = [
    aws_route_table.private_route_table.id,
    aws_route_table.public_route_table.id
  ]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "*"
      Resource  = "*"
    }]
  })
}

# Create all resources for the AWS Batch compute environment-------------------------------------------------------

# Create IAM role document
data "aws_iam_policy_document" "batch_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["batch.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Create IAM role for AWS batch servers
resource "aws_iam_role" "aws_batch_service_role" {
  name               = "aws_batch_service_role"
  assume_role_policy = data.aws_iam_policy_document.batch_assume_role.json
}

# Attach IAM role policy
resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role       = aws_iam_role.aws_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# Create AWS Batch compute environment
resource "aws_batch_compute_environment" "artis_compute_env" {
  compute_environment_name = "artis-compute-env"
  compute_resources {
    max_vcpus          = 256
    security_group_ids = [aws_security_group.vpc_security_group.id]
    subnets = [
      aws_subnet.public_subnet.id,
      aws_subnet.private_subnet1.id,
      aws_subnet.private_subnet2.id,
      aws_subnet.private_subnet3.id,
      aws_subnet.private_subnet4.id,
      aws_subnet.private_subnet5.id,
      aws_subnet.private_subnet6.id
    ]
    type = "FARGATE"
  }
  service_role = aws_iam_role.aws_batch_service_role.arn
  type         = "MANAGED"
  depends_on = [
    aws_iam_role_policy_attachment.aws_batch_service_role
  ]
}

# Create a job queue and place it within the compute environment
resource "aws_batch_job_queue" "job_queue" {
  name     = "artis-job-queue"
  state    = "ENABLED"
  priority = 1000
  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.artis_compute_env.arn
  }
}

# Creating a Job definition---------------------------------------------------------

# IAM policy document (Trusted entities)
data "aws_iam_policy_document" "job_def_policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com",
        "s3.amazonaws.com",
        "ec2.amazonaws.com"
      ]
    }
  }
}

# IAM role for AWS Batch ECS task execution
resource "aws_iam_role" "ecs_task_exec_role" {
  name               = "ecs_task_exec_role"
  assume_role_policy = data.aws_iam_policy_document.job_def_policy_doc.json
}

# Add policy permissions to ECS task exec role------------------------------------------------
# Attaching Amazon ECS task execution role policy to IAM role created for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_exec_role_policy1" {
  role       = aws_iam_role.ecs_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_role_policy2" {
  role       = aws_iam_role.ecs_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_role_policy3" {
  role       = aws_iam_role.ecs_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_role_policy4" {
  role       = aws_iam_role.ecs_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_role_policy5" {
  role       = aws_iam_role.ecs_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_role_policy6" {
  role       = aws_iam_role.ecs_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_role_policy7" {
  role       = aws_iam_role.ecs_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_role_policy8" {
  role       = aws_iam_role.ecs_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_role_policy9" {
  role       = aws_iam_role.ecs_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
#----------------------------------------------------------------------------------------------

# AWS Batch Job Definition using Fargate platform
resource "aws_batch_job_definition" "artis_job_def" {
  name = "artis_job_definition"
  type = "container"
  platform_capabilities = [
    "FARGATE"
  ]

  container_properties = jsonencode({
    # Job Definition name
    name = var.job_def_name
    # Default command to Docker image is "echo test"
    command = ["echo", "test"]

    # Additional job environment setup options
    /*
    networkConfiguration  = {}
    repositoryCredentials = {}
    secrets               = []
    environment           = []
    linuxParameters       = {}
    mountPoints           = []
    logConfiguration = {
      options       = {}
      secretOptions = {}
    }
    */

    # Set to try a job at least X amount of times (set as a variable in "variables.tf")
    retry_strategy = {
      attempts = var.job_retry_attempts
    }

    # Currently - No additional memory will be allocated besides the amount specified
    # However can be customized to include additional memory if needed
    /*
    ephemeralStorage = {
      sizeInGiB = null
    }
    */

    # Docker image URL from your ECR repository
    image = format(
      "%s:%s",
      aws_ecr_repository.artis_hs_ecr.repository_url,
      var.docker_version_tag
    )

    # Set to use the latest version of Fargate
    platform_capabilities = [
      "FARGATE"
    ]
    fargatePlatformConfiguration = {
      platformVersion = "LATEST"
    }

    # Requirements that each server running a job should have
    resourceRequirements = [
      {
        "type" : "VCPU",
        "value" : "16.0"
      },
      {
        "type" : "MEMORY",
        "value" : "122880" # 120 GB #"65536" # 64 GB
      }
    ]

    # Set to use a Linux system running on a intel x86_64 chip
    runtimePlatform = {
      "cpuArchitecture" : var.chip_arch,
      "operatingSystemFamily" : "LINUX"
    }

    # Set to root user to have all admin priviledges
    user = "root"

    # Execution role for jobs submitted using this task
    executionRoleArn = aws_iam_role.ecs_task_exec_role.arn

    # Job role for jobs submitted using this task allowing all S3 uploads
    jobRoleArn = aws_iam_role.ecs_task_exec_role.arn
  })
}

