# ARTIS HPC

This repository automates and orchestrates running the ARTIS model on AWS Batch. It supports two primary workflows:

1. **Full (brand-new) setup**  
   - provision AWS infrastructure
   - build and push Docker images
   - upload model inputs
   - submit Batch jobs

2. **Incremental or restart runs**  
   - re-use existing AWS resources and Docker image
   - upload updated model inputs
   - submit Batch jobs (including a “restart at get_snet” option if needed).

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

ARTIS HPC uses AWS Batch, S3, Terraform, Docker, Python, and R to run the ARTIS model across all HS versions and year combinations.  

- The **ARTIS R package** (in [Seafood-Globalization-Lab/artis-model](https://github.com/Seafood-Globalization-Lab/artis-model)) contains all model functions and pipeline scripts.  
- This **artis-hpc** repo sets up the compute tools, environments and resources:  
  - Provision EC2/VPC/Batch via Terraform.  
  - Build a Docker image (`artis-image`) containing software installations and necessary R/py packages.  
  - Push Docker image to ECR. 
  - Push code and data inputs to S3.  
  - Submit AWS Batch jobs for each HS version.  
  - Download results to local machine repo directory
  - (Optional) Resume a failed `get_snet()` step without re-solving the mass-balance (new “restart” tooling).

## ARTIS Version Compatibility

- **Required ARTIS Model Version:** [`Seafood-Globalization-Lab/artis-model@v1.1.0`](https://github.com/Seafood-Globalization-Lab/artis-model/releases/tag/v1.1.0)

## Prerequisites

Before submitting any ARTIS jobs, complete the following setup:

4. **Required Tools (macOS or Linux)**  [Intall instructions](#installations) 
   - **Docker Desktop** 
   - **Terraform CLI**  
   - **AWS CLI** (v2)
   - **Python 3.11+** 
   - **R** (for ARTIS‐model code; not required to run the setup script but used by AWS Batch containers).

2. **Local Repositories**  
   - Clone (or have) a local copy of `Seafood-Globalization-Lab/artis-hpc` 
      ```zsh
      git clone https://github.com/Seafood-Globalization-Lab/artis-hpc.git
      ```
   
   - Clone (or have) a local copy of `Seafood-Globalization-Lab/artis-model` so that the `artis-hpc/setup_artis_hpc.sh` script can copy relevant model code, scripts, and input data into your local `artis-hpc` repo.
      ```zsh
      git clone https://github.com/Seafood-Globalization-Lab/artis-model.git
      ```

1. **AWS Credentials & IAM Access**  

   > [!NOTE]  
   > Create IAM resources as needed (One‐time) with these instructions [docs/iam-setup.md](docs/iam-setup.md)
   - Ensure you have an IAM user in an Admin group with `AdministratorAccess`. 
  

## Run ARTIS on AWS Instructions

 - **Set your AWS credentials** as environment variables in your shell (replace with your values):  
     ```zsh
     export AWS_ACCESS_KEY=[YOUR_AWS_ACCESS_KEY]
     export AWS_SECRET_ACCESS_KEY=[YOUR_AWS_SECRET_ACCESS_KEY]
     export AWS_REGION=us-east-1
     ```

     ```
     #check value with 
     echo $AWS_ACCESS_KEY
     ```
- **Set AWS configuration files**  (`~/.aws/credentials` and `~/.aws/config`)
     ```zsh
     aws configure set aws_access_key_id $AWS_ACCESS_KEY
     aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
     aws configure set region $AWS_REGION
     ```

     ```
     #check value with 
     aws configure get aws_access_key_id
     ```
- **Set HS_VERSIONS** to run:
     ```zsh
     export HS_VERSIONS="02,07,12,17,96"
     ```
   - This must be set before running the setup script (it is required in  `create_pipeline_versions.sh` and `submit_artis_jobs.py`).

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

## Installations

-   [Homebrew](#homebrew-installation)
-   [AWS CLI](#aws-cli-installation)
-   [Terraform CLI](#terraform-cli-installation)
-   [Python Installation](#python-installation)
    -   Python packages
        -   docker
        -   boto3
-   [Docker Desktop](#)

### Homebrew Installation

**Note**: If you already have Homebrew installed please still confirm by following step 3 below. Both instructions should run without an error message.

1.  Install homebrew - **run**$

``` sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2.  **Close** existing terminal window where installation command was run and **open** a new terminal window
3.  Confirm homebrew has been installed -
    - **Run** $`brew --version`. No error message should appear.

*If after homebrew installation you get a message stating* `brew command not found`:

4.  Edit zsh config file, **run** $`vim ~/.zshrc`

5.  **Type** `i` to enter edit mode
6.  **Copy & paste** this line into the file you opened:

``` sh
export PATH=/opt/homebrew/bin:$PATH
```

7.  **Press** `Shift` and :
8.  **Type** `wq`
9.  **Press** `Enter`
10. Source new config file, **run** $`source ~/.zshrc`

### Docker Desktop Installation

The Docker desktop app contains Docker daemon which is required to run in the background to build docker images. Docker CLI (command line interface) is a client, CLI commands call on this service to do the work. 

1. [Install here](https://docs.docker.com/desktop/setup/install/mac-install/)
2. Complete installation by opening `Docker.dmg` on your machine.



### AWS CLI Installation

[Following instructions from AWS](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

**Note**: If you already have AWS CLI installed please still confirm by following step 3 below. Both instructions should run without an error message.

The following instructions are for MacOS users:

1.  **Run** $`curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"`
2.  **Run** $`sudo installer -pkg AWSCLIV2.pkg -target /`
3.  Confirm AWS CLI has been installed:
    1.  **Run** $`which aws`
    2.  **Run** $`aws --version`

### Terraform CLI Installation

**Note**: If you already have homebrew installed please confirm by **running** $`brew --version`, no error message should occur.

To install terraform on MacOS we will be using homebrew. If you do not have homebrew installed on your computer please follow the installation instructions [here](https://brew.sh/), before continuing.

Based on Terraform CLI installation instructions provided [here](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

1.  **Run** $`brew tap hashicorp/tap`
2.  **Run** $`brew install hashicorp/tap/terraform`
3.  **Run** $`brew update`
4.  **Run** $`brew upgrade hashicorp/tap/terraform`

If this has been unsuccessful you might need to install xcode command line tools, try:

5.  Run terminal command: `sudo xcode-select --install`

### Python Installation

- install python 3.11 on MacOS: **Run** $`brew install python@3.11`
- check python 3.11 has been installed: **Run** $`python3 --version`
- install pip (package installer for python): **Run** $`sudo easy_install pip`


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

