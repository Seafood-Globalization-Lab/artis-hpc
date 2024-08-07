# R version of s3 bucket
# Note: the python version is faster, 
# but this provides an option if the python version is not working

# Load packages
library(tidyverse)
library(aws.s3)

# Set output directory
outdir <- "/Volumes/T7/ARTIS/aws_runs"

# Set location for s3 bucket on AWS
s3_bucket_name <- "s3://artis-s3-bucket/"
s3_region <- "us-east-1"

artis_dir <- "outputs"

# List files to download
df_files <- get_bucket_df(
  bucket = s3_bucket_name,
  region = s3_region,
  prefix = artis_dir,
  max = Inf
) %>%
  pull(Key) %>%
  unique()

# Filter out file paths to folders
df_files <- df_files[str_detect(df_files, pattern = "\\.")]

# Loop through to download each file
for (i in 1:length(df_files)) {
  print(paste(i, "of", length(df_files), df_files[i], sep = " "))
  
  save_object(
    object = df_files[i],
    bucket = s3_bucket_name,
    file = file.path(outdir, df_files[i])
  )
}

print("Done!")
