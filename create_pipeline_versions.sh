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

# Define function to create ARTIS scripts for each HS version specified
create_modified_script() {
  local original_script_path=$1
  local script_name=$2
  local replace_source=$3

  # Check if the original script exists
  if [ ! -f "$original_script_path" ]; then
    echo "Original script not found at $original_script_path!"
    exit 1
  fi

  # Read the original script into a variable
  original_script=$(cat "$original_script_path")

  # Find the line number of the line containing that sets 'hs_version_run <-'
  line_number=$(grep -n "hs_version_run *<-" "$original_script_path" | cut -d: -f1)

  if [ -z "$line_number" ]; then
    echo "Could not find 'hs_version_run <-' in $original_script_path"
    exit 1
  fi

  # Loop through each HS version and create a new script
  for hs_version in "${hs_versions[@]}"
  do
    # Modify the relevant line to set hs_version_run
    modified_script=$(echo "$original_script" | sed "${line_number}s/.*/hs_version_run <- \"$hs_version\"/")

    # Define the new file name
    new_file_name="data_s3_upload/ARTIS_model_code/${script_name}_hs${hs_version}.R"

    # Write the modified script to a new file
    echo "$modified_script" > "$new_file_name"

    # Print a message to confirm the file creation
    echo "Created $new_file_name with hs_version_run set to $hs_version"
  done
}


# Create modified versions of 02-artis-pipeline.R and update 
# 00-aws-setup script sourced on line 13 to now call hs_version specific script
create_modified_script "$pipeline_script_path" "02-artis-pipeline" true

# Print a final message to confirm the process is done
echo "All HS version scripts have been created successfully!"
