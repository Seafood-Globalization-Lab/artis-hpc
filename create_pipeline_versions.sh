#!/bin/bash

# Ensure HS_VERSIONS is set
if [ -z "$HS_VERSIONS" ]; then
  echo "HS_VERSIONS environment variable is not set!"
  exit 1
fi

# Convert HS_VERSIONS to an array
IFS=',' read -r -a hs_versions <<< "$HS_VERSIONS"

# Path to the original script
original_script_path="data_s3_upload/ARTIS_model_code/02-artis-pipeline.R"

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
  # Modify the relevant line (29th line)
  modified_script=$(echo "$original_script" | sed "29s/.*/hs_version_run <- \"$hs_version\"/")

  # Define the new file name
  new_file_name="data_s3_upload/ARTIS_model_code/02-artis-pipeline-hs${hs_version}.R"

  # Write the modified script to a new file
  echo "$modified_script" > "$new_file_name"

  # Print a message to confirm the file creation
  echo "Created $new_file_name with hs_version_run set to $hs_version"
done

# Print a final message to confirm the process is done
echo "All HS version pipeline scripts have been created successfully!"
