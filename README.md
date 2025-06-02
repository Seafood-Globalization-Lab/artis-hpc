# ARTIS HPC

This repository automates and orchestrates running the ARTIS model on AWS Batch. It supports two primary workflows:

1. **Full (brand-new) setup**  
   Provision AWS infrastructure, build and push Docker images, upload model inputs, and submit Batch jobs from scratch.

2. **Incremental or restart runs**  
   Re-use existing AWS resources and Docker image, upload updated model inputs, and submit new Batch jobs (including a “resume at get_snet” option if needed).

**Primary Audience**  
A technically proficient data scientist (macOS) who maintains, develops, and runs the ARTIS pipeline on AWS. Detailed documentation is provided so future maintainers can pick up this project even if they start from scratch.

---

## Table of Contents

- [Overview](#overview)
- [Version Compatibility](#version-compatibility)
- [Technologies Used](#technologies-used)
- [Assumptions](#assumptions)
- [Installations](#installations)
- [Setup Local Python Environment](#setup-local-python-environment)
- [AWS CLI Setup](#aws-cli-setup)
- [Optional: `setup_artis_hpc.sh` Script](#optional-setup_artis_hpc.sh-script)
- [Update ARTIS Model Scripts and Model Inputs](#update-artis-model-scripts-and-model-inputs)
- [Setting Up New ARTIS HPC on AWS](#setting-up-new-artis-hpc-on-aws)
- [Running Existing ARTIS HPC Setup](#running-existing-artis-hpc-setup)
- [Combine ARTIS model outputs into CSVs](#combine-artis-model-outputs-into-csvs)
- [Download Results, Clean Up AWS and Docker Environments](#download-results-clean-up-aws-and-docker-environments)
- [Checks & Troubleshooting](#checks-troubleshooting)

## Overview

ARTIS HPC uses AWS Batch, S3, Terraform, Docker, Python, and R to run the ARTIS seafood‐trade model at scale.  

- The **ARTIS R package** (in [Seafood-Globalization-Lab/artis-model](https://github.com/Seafood-Globalization-Lab/artis-model)) contains all core model functions.  
- This **artis-hpc** repo glues everything together:  
  1. Provision EC2/VPC/Batch via Terraform.  
  2. Build a Docker image (`artis-image`) containing R, Python, and necessary R/py packages.  
  3. Push code and inputs to S3.  
  4. Submit AWS Batch jobs for each HS version.  
  5. (Optional) Resume a failed `get_snet()` step without re-solving the mass-balance (new “restart” tooling).

## Version Compatibility

- **Required ARTIS Model Version:** [`Seafood-Globalization-Lab/artis-model@v1.1.0`](https://github.com/Seafood-Globalization-Lab/artis-model/releases/tag/v1.1.0)

## Quick-Start

If your AWS infrastructure already exists (all Terraform resources are live) and you have the Docker image (`artis-image`) in ECR, you can run a model update in four steps:

1. **Activate Python virtual environment**  
   ```zsh
   source venv/bin/activate
   ```

2. **Upload updated ARTIS code/inputs to S3**  
   ```zsh
   python3 s3_upload.py
   ```

3. **Submit new ARTIS Batch jobs**  
   ```zsh
   python3 submit_artis_jobs.py
   ```

4. **Once jobs finish: Download outputs and tear down AWS resources**  
   ```zsh
   python3 s3_download.py
   terraform destroy
   deactivate
   ```

That’s it—no need to run the full provisioning steps again.

## Prerequisites

Before submitting any ARTIS jobs, complete the following setup:

1. **AWS Credentials & IAM Access**  
   - Ensure you have an IAM user in an Admin group with `AdministratorAccess`.  
   - Export these environment variables in your shell (replace with your values):  
     ```zsh
     export AWS_ACCESS_KEY=[YOUR_AWS_ACCESS_KEY]
     export AWS_SECRET_ACCESS_KEY=[YOUR_AWS_SECRET_ACCESS_KEY]
     export AWS_REGION=us-east-1
     ```
   - (One‐time) Create IAM resources as needed—see [docs/iam-setup.md](docs/iam-setup.md).

2. **Local Repositories**  
   - Clone (or have) a local copy of `Seafood-Globalization-Lab/artis-model` so the setup script can copy R scripts and package files.  
      ```zsh
   git clone https://github.com/Seafood-Globalization-Lab/artis-hpc.git
   cd artis-hpc
   ```

3. **Set HS_VERSIONS**  
   - Define which HS versions you’ll run, for example:  
     ```zsh
     export HS_VERSIONS="02,07,12,17,96"
     ```
   - This must be set before running the setup script (it drives `create_pipeline_versions.sh`).

4. **Required Tools (macOS or Linux)**  
   - **Git** (to clone repos).  
   - **Docker Desktop** (latest).  
   - **Terraform CLI** (v1.x) in your `PATH`.  
   - **AWS CLI** (v2) in your `PATH`.  
   - **Python 3.11+** installed.  
   - **R** (for ARTIS‐model code; not required to run the setup script but used by AWS Batch containers).

---

## Full Setup (New ARTIS HPC)

1. **Edit directory paths in the setup script**  
   Open `setup_artis_hpc.sh` and update these variables at the top to match your local clones:
   ```bash
   # Path to artis-model code
   ARTIS_MODEL_CODE_DIR="/path/to/your/artis-model"

   # Path to artis-hpc repo root
   ARTIS_HPC_DIR="/path/to/your/artis-hpc"
   ```

2. **Run the setup helper script**  
   ```zsh
   cd /path/to/artis-hpc
   chmod +x setup_artis_hpc.sh
   ./setup_artis_hpc.sh
   ```
   This will:
   1. Copy `00-aws-hpc-setup.R`, `02-artis-pipeline.R`, and R package files (`R/`, `DESCRIPTION`, `NAMESPACE`, optional `.Renviron`) from your ARTIS model clone into `data_s3_upload/ARTIS_model_code/`.  
   2. Sync model inputs (excluding `*_including_value.csv`) into `data_s3_upload/model_inputs/`.  
   3. Run `create_pipeline_versions.sh` (reads `HS_VERSIONS`) to generate HS‐specific R scripts under `ARTIS_model_code/`.  
   4. Create or recreate the Python virtual environment `venv/` and install dependencies from `requirements.txt`, with fallback logic on failure.  
   5. Verify `AWS_ACCESS_KEY` + `AWS_SECRET_ACCESS_KEY` are set, export `AWS_REGION`, and run `aws configure set` to store credentials.

3. **Upload ARTIS code & inputs to S3**  
   ```zsh
   source venv/bin/activate
   python3 s3_upload.py
   ```
   - Syncs `data_s3_upload/ARTIS_model_code/` and `data_s3_upload/model_inputs/` to your S3 bucket (e.g., `s3://artis-s3-bucket/`).

4. **Provision AWS & Build Docker image**  
   ```zsh
   python3 initial_setup.py \
     -chip arm64 \
     -aws_access_key $AWS_ACCESS_KEY \
     -aws_secret_key $AWS_SECRET_ACCESS_KEY \
     -s3 artis-s3-bucket \
     -ecr artis-image
   ```
   - `-chip` can be `arm64` (M1/M2 Mac) or `x86`.  
   - `-s3` is your existing S3 bucket name.  
   - `-ecr` is the ECR repository name for `artis-image`.  
   - **Optional:** add `-di artis-image:latest` to skip Docker build if you already have an image in ECR.

   **This does:**
   1. Copies the correct Dockerfile (ARM64 vs. X86) to `./Dockerfile`.  
   2. Injects AWS credentials into `./Dockerfile` and `.Renviron`.  
   3. Updates Terraform files (`main.tf`, `variables.tf`) with S3/ECR names.  
   4. Runs `terraform init`, `terraform fmt`, `terraform validate`, and `terraform apply -auto-approve` to create VPC, Subnets, Security Groups, IAM Roles, Batch Compute Environments, Job Queues, etc.  
   5. Builds and pushes the `artis-image` Docker image.  
   6. Stops before submitting Batch jobs (proceed to next step).  
   7. If anything fails, runs `terraform destroy` to clean up.

5. **Submit initial ARTIS Batch jobs**  
   ```zsh
   python3 submit_artis_jobs.py
   ```
   - Loops over each HS version in `HS_VERSIONS` and runs `02-artis-pipeline_hsXX.R` inside the container.

6. **Monitor progress**  
   - Check AWS Batch job statuses in the AWS console.  
   - View CloudWatch logs under `/aws/batch/job/...` for `get_country_solutions()` and `get_snet()` output.

7. **Download results & tear down**  
   ```zsh
   python3 s3_download.py
   terraform destroy
   deactivate
   ```
   - Downloads outputs into `outputs_[RUN_DATE]/…`.  
   - Removes all AWS resources via Terraform.  
   - You may manually empty or retain the S3 bucket for future runs. 

## Restarting ARTIS (Incremental Run)

**Use case:** You already have AWS infrastructure and the `artis-image` Docker image in place. To resume a failed `get_snet()` or update code/inputs:

1. **Activate Python environment**  
   ```zsh
   cd /path/to/artis-hpc
   source venv/bin/activate
   ```

2. **(If needed) Update HS versions**  
   ```zsh
   export HS_VERSIONS="96"
   ./create_pipeline_versions.sh
   ```

3. **Sync changes to S3**  
   Ensure `data_s3_upload/ARTIS_model_code/` is updated accordingly. Currently requires manual upload on web interface to prevent entire upload to s3. This saves time. 

4. **Restart at `get_snet()`**  
   ```zsh
   python3 submit_restart_artis_snet_jobs.py
   ```
   - Uses the HS-specific `02-artis-pipeline-restart-snet-hsXX.R` scripts to skip `get_country_solutions()` and resume `get_snet()`.

6. **Monitor and retrieve results**  
   - Check AWS Batch and CloudWatch logs for job status.  
   - After completion:
     ```zsh
     python3 s3_download.py
     terraform destroy   # if tearing down
     deactivate
     ```
   - Outputs appear under `outputs_[RUN_DATE]/…`.  


## S3 Bucket & Output Structure

Below is the expected layout under your S3 bucket (e.g., `s3://artis-s3-bucket/outputs/`):

```text
s3://artis-s3-bucket/outputs/
├── cvxopt_snet/
│   ├── HS[VERSION]/
│   │   ├── [YEAR]/
│   │   │   ├── [RUN DATE]_all-country-est_[YEAR]_HS[VERSION].RDS
│   │   │   ├── [RUN DATE]_all-data-prior-to-solve-country_[YEAR]_HS[VERSION].RData
│   │   │   ├── [RUN DATE]_analysis-documentation_countries-with-no-solve-qp-solution_[YEAR]_HS[VERSION].txt
│   │   │   ├── [RUN DATE]_country-est_[COUNTRY ISO3C]_[YEAR]_HS[VERSION].RDS
│   │   │   └── … (other per-country RDS files)
│   │   ├── [YEAR]/
│   │   │   └── … (same pattern)
│   │   └── no_solve_countries.csv
│   └── … (other HS versions)
├── quadprog_snet/
│   ├── HS[VERSION]/
│   │   ├── [YEAR]/
│   │   │   ├── [RUN DATE]_all-country-est_[YEAR]_HS[VERSION].RDS
│   │   │   ├── [RUN DATE]_all-data-prior-to-solve-country_[YEAR]_HS[VERSION].RData
│   │   │   ├── [RUN DATE]_analysis-documentation_countries-with-no-solve-qp-solution_[YEAR]_HS[VERSION].txt
│   │   │   ├── [RUN DATE]_country-est_[COUNTRY ISO3C]_[YEAR]_HS[VERSION].RDS
│   │   │   └── … (other per-country RDS files)
│   │   ├── [YEAR]/
│   │   │   └── … (same pattern)
│   │   └── no_solve_countries.csv
│   └── … (other HS versions)
├── snet/
│   ├── HS[VERSION]/
│   │   ├── [YEAR]/
│   │   │   ├── [RUN DATE]_S-net_raw_midpoint_[YEAR]_HS[VERSION].qs
│   │   │   ├── [RUN DATE]_all-country-est_[YEAR]_HS[VERSION].RDS
│   │   │   ├── [RUN DATE]_consumption_[YEAR]_HS[VERSION].qs
│   │   │   ├── W_long_[YEAR]_HS[VERSION].csv
│   │   │   ├── X_long.csv
│   │   │   ├── first_dom_exp_midpoint.csv
│   │   │   ├── first_error_exp_midpoint.csv
│   │   │   ├── first_foreign_exp_midpoint.csv
│   │   │   ├── first_unresolved_foreign_exp_midpoint.csv
│   │   │   ├── hs_clade_match.csv
│   │   │   ├── reweight_W_long_[YEAR]_HS[VERSION].csv
│   │   │   ├── reweight_X_long_[YEAR]_HS[VERSION].csv
│   │   │   ├── second_dom_exp_midpoint.csv
│   │   │   ├── second_error_exp_midpoint.csv
│   │   │   ├── second_foreign_exp_midpoint.csv
│   │   │   ├── second_unresolved_foreign_exp_midpoint.csv
│   │   │   └── … (other intermediate CSVs)
│   │   ├── V1_long_HS[VERSION].csv
│   │   ├── V2_long_HS[VERSION].csv
│   │   └── … (other global CSVs)
│   └── … (other HS versions)
```

## Checks & Troubleshooting 

### Status of jobs submitted to AWS Batch

1.   Navigate to AWS in your browser and log in to your IAM account.  
2.   Use the search bar at the top of the page to search for “Batch” and click on the service Batch result.  

    ![AWS Search](./images/aws_batch_search.png)

3.   Under “Job queue overview” you will be able to see job statuses and click on the number to open details.  

    ![AWS Batch → Dashboard](./images/aws_batch_dash.png)  
      
4.   Investigate individual job status and details through filters (be sure to click “Search”).

    ![AWS Batch → Jobs](./images/aws_batch_jobs.png)

### Troubleshoot failed jobs

1.   Set “Filter type” to “Status” and “Filter value” to “FAILED” in AWS Batch → Jobs window above. Click “Search”.  
2.   Identify and open relevant failed job by clicking on job name.  
3.   Inspect “Details” for failed job; “Status Reason” is particularly helpful.  
4.   Click on “Log stream name” to open CloudWatch logs for the specific job. This displays the code output and error messages.  
    - **Note:** The “AWS Batch → Jobs → your-job-name” image below shows a common error message `ResourceInitializationError: unable to pull secrets or registry auth: […]` when there is an issue initializing the resources required by the AWS Batch job. This is most likely a temporary network issue and can be resolved by re-running the specific job (HS version).

    ![AWS Batch → Jobs → your-job-name](./images/aws_job_fail_error.png)

**Note:** The image above shows a common error message when the model code is unable to find the correct file path.

### Check CloudWatch logs for a specific job

1.   Search for “CloudWatch” in the search bar and click on the service CloudWatch.  
2.   In the left‐hand nav‐bar click on “Logs” → “Log groups” → `/aws/batch/job`.  
3.   Inspect “Log streams” (sorted by “Last Event Time”) to identify and open the correct log.  
4.   Inspect messages, output, and errors from running the model code.

### Check for all expected outputs in S3 bucket

1.   Navigate to the `artis-s3-bucket` in AWS S3.  
2.   Confirm that all expected outputs are present for the ARTIS model jobs.  
    - The `outputs` folder should contain a `snet/` subfolder that has each HS version specified in the `HS_VERSIONS` variable.  
    - Each HS version folder should contain the applicable years.

- Replace `[VERSION]` with the HS version code (e.g., `96`, `02`, etc.).  
- Replace `[YEAR]` with the calendar year (e.g., `1996`, `1997`, …).  
- `[RUN DATE]` is the date‐stamp of the model run in `YYYY-MM-DD` format.  
- Files ending in `.qs` are serialized with `qs2::qsave(...)`; the batch containers read/write them natively.  
- The `artis_outputs/` folder is produced after running the combine‐tables job.

