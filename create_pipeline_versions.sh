#!/bin/bash

# Ensure HS_VERSIONS is set
if [ -z "$HS_VERSIONS" ]; then
  echo "HS_VERSIONS environment variable is not set!"
  exit 1
fi

# Convert HS_VERSIONS to an array
IFS=',' read -r -a hs_versions <<< "$HS_VERSIONS"

# Paths to the original scripts
pipeline_script_path="data_s3_upload/ARTIS_model_code/02-artis-pipeline.R"
aws_setup_script_path="data_s3_upload/ARTIS_model_code/00-aws-hpc-setup.R"

# Function to create modified scripts
create_modified_script() {
  local original_script_path=$1
  local line_number=$2
  local script_name=$3
  local replace_source=$4

  # Check if the original script exists
  if [ ! -f "$original_script_path" ]; then
    echo "Original script not found at $original_script_path!"
    exit 1
  fi

  # Read the original script into a variable
  original_script=$(cat "$original_script_path")

  # Loop through each HS version and create a new script
  for hs_version in "${hs_versions[@]}"
  do
    # Modify the relevant line to set hs_version_run
    modified_script=$(echo "$original_script" | sed "${line_number}s/.*/hs_version_run <- \"$hs_version\"/")

    # Replace the source line if required
    if [ "$replace_source" = true ]; then
      modified_script=$(echo "$modified_script" | sed "13s|source(\"00-aws-hpc-setup.R\")|source(\"00-aws-hpc-setup_hs${hs_version}.R\")|")
    fi

    # Define the new file name
    new_file_name="data_s3_upload/ARTIS_model_code/${script_name}_hs${hs_version}.R"

    # Write the modified script to a new file
    echo "$modified_script" > "$new_file_name"

    # Print a message to confirm the file creation
    echo "Created $new_file_name with hs_version_run set to $hs_version"
  done
}

# Create modified versions for 02-artis-pipeline.R (29th line) and update source on line 13
create_modified_script "$pipeline_script_path" 29 "02-artis-pipeline" true

# Create modified versions for 00-aws-hpc-setup.R (28th line)
create_modified_script "$aws_setup_script_path" 28 "00-aws-hpc-setup" false

# Print a final message to confirm the process is done
echo "All HS version scripts have been created successfully!"
