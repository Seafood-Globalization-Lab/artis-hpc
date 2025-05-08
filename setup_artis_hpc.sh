#!/bin/bash

# =====================================================================
# ARTIS HPC Setup Script
# Purpose: Automate the update of ARTIS model scripts, inputs, and environment variables
# Based on ARTIS HPC GitHub README instructions
# =====================================================================

set -e  # Exit immediately on error

# ---------------------------
# User Inputs (EDIT THESE)
# ---------------------------

# Path to artis-model code
ARTIS_MODEL_CODE_DIR="/Users/theamarks/Documents/git-projects/artis-model"

# Path to artis-hpc repo root
ARTIS_HPC_DIR="/Users/theamarks/Documents/git-projects/artis-hpc"

# Set HS_VERSIONS (comma-separated, no spaces)
HS_VERSIONS="96"

# ---------------------------
# Directory Setup & Validation
# ---------------------------

ARTIS_HPC_CODE_DIR="${ARTIS_HPC_DIR}/data_s3_upload/ARTIS_model_code"
ARTIS_HPC_INPUTS_DIR="${ARTIS_HPC_DIR}/data_s3_upload/model_inputs"

echo "Ensuring ARTIS_model_code and model_inputs directories exist and are cleared (but retain .gitkeep)..."

ensure_empty_hpc_dir() {
  local dir_path=$1
  local label=$2
  if [ ! -d "$dir_path" ]; then
    echo "$label does not exist. Creating..."
    mkdir -p "$dir_path"
    touch "${dir_path}/.gitkeep"
  else
    echo "Clearing contents of $label except .gitkeep..."
    find "$dir_path" -mindepth 1 ! -name '.gitkeep' -exec rm -rf {} +
  fi
}

ensure_empty_hpc_dir "$ARTIS_HPC_CODE_DIR" "ARTIS_model_code"
ensure_empty_hpc_dir "$ARTIS_HPC_INPUTS_DIR" "model_inputs"

# ---------------------------
# Copy scripts and inputs
# ---------------------------
echo "Copying model scripts..."
cp "${ARTIS_MODEL_CODE_DIR}/00-aws-hpc-setup.R" "${ARTIS_HPC_CODE_DIR}/"
cp "${ARTIS_MODEL_CODE_DIR}/02-artis-pipeline.R" "${ARTIS_HPC_CODE_DIR}/"

echo "Copying model inputs (excluding *_including_value.csv)..."
rsync -av --delete \
  --exclude 'standardized_baci_seafood*including_value.csv' \
  "${ARTIS_MODEL_CODE_DIR}/model_inputs/" "${ARTIS_HPC_INPUTS_DIR}/"

echo "Copying ARTIS R package metadata..."
rsync -av --delete "${ARTIS_MODEL_CODE_DIR}/R/" "${ARTIS_HPC_CODE_DIR}/R/"
cp "${ARTIS_MODEL_CODE_DIR}/DESCRIPTION" "${ARTIS_HPC_CODE_DIR}/DESCRIPTION"
cp "${ARTIS_MODEL_CODE_DIR}/NAMESPACE" "${ARTIS_HPC_CODE_DIR}/NAMESPACE"

if [ -f "${ARTIS_MODEL_CODE_DIR}/.Renviron" ]; then
  echo "Copying .Renviron..."
  cp "${ARTIS_MODEL_CODE_DIR}/.Renviron" "${ARTIS_HPC_CODE_DIR}/.Renviron"
else
  echo "No .Renviron file found. Skipping..."
fi

# ---------------------------
# Set HS_VERSIONS for later scripts
# ---------------------------
echo "Setting HS_VERSIONS..."
export HS_VERSIONS="$HS_VERSIONS"

# ---------------------------
# Run create_pipeline_versions.sh
# ---------------------------
CREATE_SCRIPT_PATH="${ARTIS_HPC_DIR}/create_pipeline_versions.sh"
if [ -f "$CREATE_SCRIPT_PATH" ]; then
  echo "Running create_pipeline_versions.sh..."
  bash "$CREATE_SCRIPT_PATH"
else
  echo "Error: create_pipeline_versions.sh not found at $CREATE_SCRIPT_PATH"
  exit 1
fi

# ---------------------------
# Optional: ARM64 Requirements
# ---------------------------
ARCHITECTURE="$(uname -m)"
if [ "$ARCHITECTURE" = "arm64" ]; then
  echo "Detected Apple Silicon. Copying ARM64 requirements.txt..."
  cp "${ARTIS_HPC_DIR}/arm64_venv_requirements.txt" "${ARTIS_HPC_DIR}/docker_image_files_original/requirements.txt"
else
  echo "Non-ARM64 architecture. Skipping ARM64 requirements."
fi

# ---------------------------
# Python Virtual Environment Setup
# ---------------------------
echo "Setting up Python virtual environment..."

CURRENT_DIR=$(pwd)
EXPECTED_DIR="${ARTIS_HPC_DIR}"
if [[ "$CURRENT_DIR" != "$EXPECTED_DIR" ]]; then
  echo "Warning: Not in expected directory:"
  echo "  Expected: $EXPECTED_DIR"
  echo "  Current : $CURRENT_DIR"
  read -p "Continue anyway? (y/n): " confirm_dir
  if [[ "$confirm_dir" != "y" ]]; then
    echo "Aborting."
    exit 1
  fi
fi

PYTHON_PATH=$(brew --prefix)/bin/python3.11
echo "Using Python at $PYTHON_PATH"

$PYTHON_PATH -m venv venv
echo "Virtual environment created at ./venv"

REQ_FILE="${ARTIS_HPC_DIR}/requirements.txt"
if pip3.11 install -r "$REQ_FILE"; then
  echo "Dependencies installed."
else
  echo "Initial install failed. Trying pip upgrade..."
  pip3.11 install --upgrade pip
  pip3.11 install -r "$REQ_FILE" || {
    echo "Manual install fallback..."
    while IFS= read -r package; do
      pip3.11 install "$package"
    done < "$REQ_FILE"
  }
fi

# ---------------------------
# AWS CLI Setup from ENV vars
# ---------------------------
echo "Configuring AWS CLI..."

if [[ -z "$AWS_ACCESS_KEY" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "Error: AWS_ACCESS_KEY or AWS_SECRET_ACCESS_KEY not set."
  echo "Please export them before running this script:"
  echo '  export AWS_ACCESS_KEY="your-access-key"'
  echo '  export AWS_SECRET_ACCESS_KEY="your-secret-key"'
  exit 1
fi

export AWS_REGION="us-east-1"
aws configure set aws_access_key_id "$AWS_ACCESS_KEY"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_REGION"

echo "AWS CLI configured."

# ---------------------------
# Done
# ---------------------------
# ---------------------------
# Done
# ---------------------------
echo "ARTIS HPC setup complete."

echo
echo "Next steps:"
echo "  1. Activate the Python virtual environment:"
echo "     source venv/bin/activate"
echo
echo "Reminder: activation must be run in the same terminal session to use installed Python packages."

