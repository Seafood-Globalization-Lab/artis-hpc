
library(devtools)
library(tidyverse)
library(reticulate)
library(aws.s3)

# set working directory within environment
setwd('/usr/src/ARTIS')

# Create and download ARTIS R package
readRenviron(".Renviron")

# ONLY UNCOMMENT IF YOU ARE RUNNING DOCKER ON A NEW MAC CHIP
use_virtualenv("/usr/src/ARTIS/venv", required = TRUE)

# Download files to create ARTIS R package from AWS S3
artis_bucket <- "s3://artis-s3-bucket/"
artis_bucket_region <- "us-east-1"

artis_r_package_dir <- "ARTIS_model_code"

# If R package directory exists - delete it
if (dir.exists("R")) { unlink("R") }

# Download all ARTIS R package files from S3 bucket
artis_r_pkg_files <- get_bucket_df(
  bucket = artis_bucket,
  region = artis_bucket_region,
  prefix = artis_r_package_dir
) %>%
  pull(Key) %>%
  unique()

# Create folder for ARTIS R package
local_pkg_dir <- "R"
dir.create(local_pkg_dir)

# string length of "ARTIS_model_code/"
start_idx <- str_length(artis_r_package_dir) + 1

# Downloading all ARTIS model run R scripts and package files
for (i in 1:length(artis_r_pkg_files)) {
  
  aws_pkg_fp <- artis_r_pkg_files[i]
  local_fp <- substr(aws_pkg_fp, start_idx + 1, str_length(aws_pkg_fp))
  
  print(paste("Downloading ", aws_pkg_fp, " to ", local_fp, sep = ""))
  save_object(
    object = aws_pkg_fp,
    bucket = artis_bucket,
    region = artis_bucket_region,
    file = local_fp
  )
}

# install ARTIS R package
devtools::install()


