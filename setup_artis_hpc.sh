#!/bin/bash

# =====================================================================
# ARTIS HPC Setup Script
# Purpose: Automate the update of ARTIS model scripts, inputs, and environment variables
# Based on ARTIS HPC GitHub README instructions
# =====================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# ---------------------------
# User Inputs (EDIT THESE)
# ---------------------------

# Set your artis-model code location (source)
ARTIS_MODEL_CODE_DIR="/Users/theamarks/Documents/git-projects/artis-model"  # <-- CHANGE THIS

# Set your artis-hpc working directory (destination)
ARTIS_HPC_DIR="/Users/theamarks/Documents/git-projects/artis-hpc"           # <-- CHANGE THIS

# Set HS_VERSIONS you plan to run (no spaces between commas)
HS_VERSIONS="02,07,12,17,96"                 # <-- CHANGE THIS IF NEEDED

# ---------------------------
# Safety Check: Confirm data_s3_upload/ is safe to overwrite
# ---------------------------
if [ "$(ls -A "${ARTIS_HPC_DIR}/data_s3_upload/")" ]; then
  echo "Warning: ${ARTIS_HPC_DIR}/data_s3_upload/ is NOT empty."
  echo "Contents:"
  ls -A "${ARTIS_HPC_DIR}/data_s3_upload/"
  echo ""
  read -p "Do you want to continue and overwrite existing files? (y/n): " confirm
  if [[ "$confirm" != "y" ]]; then
    echo "Exiting script to avoid overwriting."
    exit 1
  fi
else
  echo "${ARTIS_HPC_DIR}/data_s3_upload/ is empty. Continuing..."
fi

# ---------------------------
# 1. Copy model R scripts to ARTIS HPC
# ---------------------------
echo "Copying model scripts..."
cp "${ARTIS_MODEL_CODE_DIR}/00-aws-hpc-setup.R" "${ARTIS_HPC_DIR}/data_s3_upload/ARTIS_model_code/"
cp "${ARTIS_MODEL_CODE_DIR}/02-artis-pipeline.R" "${ARTIS_HPC_DIR}/data_s3_upload/ARTIS_model_code/"
# Note: 03-combine-tables.R intentionally not copied

# ---------------------------
# 2. Copy model input folder (excluding large value-added CSVs)
# ---------------------------
echo "Copying model input folder, excluding standardized_baci_seafood*including_value.csv files..."
rsync -av --delete \
  --exclude 'standardized_baci_seafood*including_value.csv' \
  "${ARTIS_MODEL_CODE_DIR}/model_inputs/" "${ARTIS_HPC_DIR}/data_s3_upload/model_inputs/"

# ---------------------------
# 3. Copy ARTIS R package folder and metadata files
# ---------------------------
echo "Copying ARTIS R package..."
rsync -av --delete "${ARTIS_MODEL_CODE_DIR}/R/" "${ARTIS_HPC_DIR}/data_s3_upload/ARTIS_model_code/R/"
cp "${ARTIS_MODEL_CODE_DIR}/DESCRIPTION" "${ARTIS_HPC_DIR}/data_s3_upload/ARTIS_model_code/DESCRIPTION"
cp "${ARTIS_MODEL_CODE_DIR}/NAMESPACE" "${ARTIS_HPC_DIR}/data_s3_upload/ARTIS_model_code/NAMESPACE"

# ---------------------------
# 4. Optional: Copy .Renviron if it exists
# ---------------------------
if [ -f "${ARTIS_MODEL_CODE_DIR}/.Renviron" ]; then
  echo "Copying .Renviron file..."
  cp "${ARTIS_MODEL_CODE_DIR}/.Renviron" "${ARTIS_HPC_DIR}/data_s3_upload/ARTIS_model_code/.Renviron"
else
  echo "No .Renviron file found. Skipping..."
fi

# ---------------------------
# 5. Set HS_VERSIONS environment variable
# ---------------------------
echo "Setting HS_VERSIONS..."
export HS_VERSIONS="$HS_VERSIONS"

# ---------------------------
# 6. Run create_pipeline_versions.sh
# ---------------------------
echo "Running create_pipeline_versions.sh..."
cd "${ARTIS_HPC_DIR}/data_s3_upload/ARTIS_model_code/"
./create_pipeline_versions.sh

# ---------------------------
# 7. Optional: Handle Apple Silicon setup
# ---------------------------
ARCHITECTURE="$(uname -m)"
if [ "$ARCHITECTURE" = "arm64" ]; then
  echo "Detected Apple Silicon chip. Copying arm64_venv_requirements.txt..."
  cp "${ARTIS_HPC_DIR}/arm64_venv_requirements.txt" "${ARTIS_HPC_DIR}/docker_image_files_original/requirements.txt"
else
  echo "Not an Apple Silicon chip. Skipping ARM-specific requirements copy."
fi

# ---------------------------
# 8. Done
# ---------------------------
echo "ARTIS HPC setup complete. You can now proceed to run initial_setup.py or AWS job submission steps."
