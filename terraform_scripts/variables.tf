
# VARIABLES THAT CAN BE CUSTOMIZED-----------------------------------------------------


# S3 bucket name
# This should be the s3 bucket you want to push model inputs and outputs to
variable "s3_bucket_name" {
  type    = string
  default = "artis-s3-bucket"
}

# ECR repository name
# This is the repository where you will keep your docker image
variable "ecr_repo_name" {
  type    = string
  default = "artis-image"
}

# Name of the docker image you created to run the ARTIS model
variable "docker_image_name" {
  type    = string
  default = "artis-image"
}

# This is the docker image version we want to use
variable "docker_version_tag" {
  type    = string
  default = "latest"
}

# Number of times you want a job to retry running if failed
variable "job_retry_attempts" {
  type    = string
  default = 2
}

# Name for job definition 
variable "job_def_name" {
  type    = string
  default = "artis_job_definition"
}

# ONLY CHANGE THESE VARIABLES IF AN UPDATE REQUIRES YOU TO------------------------------
# Service name for S3 bucket endpoint for VPC
variable "s3_service_name" {
  type    = string
  default = "com.amazonaws.us-east-1.s3"
}

# Service name for ECR API endpoint for VPC
variable "ecr_api_service_name" {
  type    = string
  default = "com.amazonaws.us-east-1.ecr.api"
}

# Service name for ECR dkr endpoint for VPC
variable "ecr_dkr_service_name" {
  type    = string
  default = "com.amazonaws.us-east-1.ecr.dkr"
}

# Service name for DynamoDB endpoint for VPC
variable "dynamodb_service_name" {
  type    = string
  default = "com.amazonaws.us-east-1.dynamodb"
}

# DO NOT CHANGE VARIABLES BELOW--------------------------------------------------------
# CIDR block for vpc
variable "cidr0" {
  type    = string
  default = "10.0.0.0/16"
}

# CIDR blocks for subnets
variable "cidr1" {
  type    = string
  default = "10.1.0.0/16"
}

variable "cidr2" {
  type    = string
  default = "10.2.0.0/16"
}

variable "cidr3" {
  type    = string
  default = "10.3.0.0/16"
}
