# ARTIS HPC

This repository contains the instructions to create the ARTIS High Performance Computer (HPC) on Amazon Web Services (AWS) and run the ARTIS model. There are two scenarios for using this repository:

1)  Setting up a new ARTIS HPC on AWS
2) Running an Existing ARTIS HPC Setup

*All commands will be run in the terminal/command line and indicated with a "$" before the command or contained within a code block*

## Assumptions:

-   An AWS root user was created (To create an AWS root user visit [ ](aws.amazon.com))
-   AWS root user has created an admin user group with "AdministratorAccess" permissions.
-   AWS root user has created IAM users
-   AWS root user has add IAM users to admin group
-   AWS IAM users have their `AWS AWS_ACCESS_KEY` and `AWS_SECRET_ACCESS_KEY`

To create an AWS IAM user follow the instructions here: [Create AWS IAM user](#create-aws-iam-user)

**Note**: If have you created *ANY* AWS RESOURCES for ARTIS manually, not including ROOT and IAM users, please delete these before continuing.

## Table of Contents

-   [Technologies Used](#technologies-used)
-   [Update ARTIS Model Scripts and Model Inputs](#update-artis-model-scripts-and-model-inputs)
-   [Installations](#installations)
    -   [Homebrew Installation](#homebrew-installation)
    -   [AWS CLI Installation](#aws-cli-installation)
    -   [Terraform CLI Installation](#terraform-cli-installation)
-   [Assumptions](#assumptions)
-   [AWS CLI Setup](#aws-cli-setup)
-   [Clear Existing AWS Resources](#clear-existing-aws-resources)
-   [Python Installation](#python-installation)
-   [Setting Up a New ARTIS HPC on AWS](#setting-up-a-new-artis-hpc-on-aws)
-   [Running an Existing ARTIS HPC Setup](#running-an-existing-artis-hpc-setup)
-   [Combine All ARTIS Model Outputs into Database Ready CSVs](#combine-all-artis-model-outputs-into-database-ready-csvs)
-   [Download Results, Clean Up AWS and Docker Environments](#download-results-clean-up-aws-and-docker-environments)
-   [Create AWS IAM user](#create-aws-iam-user)

## Technologies Used 

-   `Terraform`
    -   Creates all the AWS infrastructure needed for the ARTIS HPC.
    -   Destroys all AWS infrastructure for the ARTIS HPC after the ARTIS model has finished to save on unnecessary costs.
-   `Docker`
    -   Creates a docker image that our HPC jobs will use to run the ARTIS model code.
-   `Python`
    -   Uses the Docker and AWS Python (boto3) clients to:
        -   Push all model input data to AWS S3
        -   Build docker image needed fir the AWS Batch jobs to run ARTIS model
        -   Push docker image to AWS ECR
        -   Submit jobs to ARTIS HPC
-   `R`
    -   Pull all model outputs data

## Update ARTIS model scripts and model inputs 

1.  At project root directory **run** $`mkdir data_s3_upload`
2.  Within `artis-hpc/data_s3_uplaod` **run** $`mkdir ARTIS_model_code`
3.  Create a copy of `02-artis-pipeline.R` script for each HS version you wish to run, and rename the scripts `02-artis-pipeline_hs[HS VERSION YOU WANT TO RUN].R` (ie for HS version 12, `02-artis-pipeline_hs12.R)`.
4.  Add on line 29 of each 02-artis-pipeline.R script the line `hs_version_run <- "[HS VERSION YOU ARE RUNNING]"` (ie for HS version 12, `hs_version_run <- "12"`)
5.  **Copy** the most up-to-date set of `model_inputs` to `artis-hpc/data_s3_upload/` directory. Retain the folder name `model_inputs`
6.  **Copy** the most up-to-date ARTIS `R/` package folder to `artis-hpc/data_s3_upload/ARTIS_model_code/`
7.  **Copy** the most up-to-date ARTIS R package `NAMESPACE` file to `artis-hpc/data_s3_upload/ARTIS_model_code/`
8.  **Copy** the most up-to-date ARTIS R package `DESCRIPTION` file to `artis-hpc/data_s3_upload/ARTIS_model_code/`
9.  **Copy** the most up-to-date .Renviron file to `artis-hpc/data_s3_upload/ARTIS_model_code/`
10. **Copy** the most up-to-date double number ARTIS `.R` scripts (i.e. `02-artis-pipeline.R`) to `artis-hpc/data_s3_upload/ARTIS_model_code/` (AM - check that this is correct)

*If running on a new Apple chip arm64*:

9.  **Copy** arm64_venv_requirements.txt file from the root directory to the `artis-hpc/docker_image_files_original/`
10.  **Rename** the file `artis-hpc/docker_image_files_original/arm64_venv_requirements.txt` to `artis-hpc/docker_image_files_original/requirements.txt`

## Installations

-   [Homebrew](#homebrew-installation)
-   [AWS CLI](#aws-cli-installation)
-   [Terraform CLI](#terraform-cli-installation)
-   Python
    -   Python packages
        -   docker
        -   boto3

### Homebrew Installation

**Note**: If you already have Homebrew installed please still confirm by following step 3 below. Both instructions should run without an error message.

1.  Install homebrew - **run**

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

## AWS CLI Setup

1.  **Run** $`export AWS_ACCESS_KEY=[YOUR_AWS_ACCESS_KEY]`
    -   sets terminal environmental variable. Replace `[YOUR_AWS_ACCESS_KEY]` with your value
2.  **Run** $`export AWS_SECRET_ACCESS_KEY=[YOUR_AWS_SECRET_ACCESS_KEY]`
    -   sets terminal environmental variable. Replace `[AWS_SECRET_ACCESS_KEY]` with your value
3.  **Run** $`export AWS_REGION=us-east-1`
    -   sets terminal environmental variable
4.  **Run** $`aws configure set aws_access_key_id $AWS_ACCESS_KEY`
    -   writes value to AWS credentials file (`~/.aws/credentials`)
5.  **Run** $`aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY`
    -   writes value to AWS credentials file (`~/.aws/credentials`)
6.  **Run** $`aws configure set region $AWS_REGION`
    -   writes value to AWS config file (`~/.aws/config`)

To check set values:

**Run** $`echo $AWS_ACCESS_KEY` to display the local environmental variable value set with the `export` command.

Likewise, **run** $`aws configure get aws_access_key_id` to print aws environment variable values stored in the AWS credentials file.

## Clear Existing AWS Resources 

[Log onto AWS](https://us-east-2.signin.aws.amazon.com/oauth?client_id=arn%3Aaws%3Asignin%3A%3A%3Aconsole%2Fcanvas&code_challenge=8nUzqNmFpMsGqg4WwTqUKFyBdVu_t_hDZMOyRX_xuoY&code_challenge_method=SHA-256&response_type=code&redirect_uri=https%3A%2F%2Fconsole.aws.amazon.com%2Fconsole%2Fhome%3FhashArgs%3D%2523%26isauthcode%3Dtrue%26nc2%3Dh_ct%26oauthStart%3D1722978779160%26src%3Dheader-signin%26state%3DhashArgsFromTB_us-east-2_2ce942407ff08169) to check if there are any model outputs that need to be retained.

## Python Installation

In order to run `initial_setup.py` we need to create a virtual environment to run the script in. **Note**: Please make sure that your terminal is currently in your working directory that should end in `artis-hpc`, by running the terminal command `pwd`.

1.  Create a virtual environment, **run** $`python3 -m venv venv`
2.  Open virtual environment, **run** $`source venv/bin/activate`
3.  Install all required python modules, **run** $`pip3 install -r requirements.txt`
4.  Check that all python modules have been downloaded, **run** $`pip3 list` and check that all modules in the `requirements.txt` file are included.

If an error occurs please follow these instructions:

5.  Upgrade your version of pip,  **run** $`pip install --upgrade pip`
6.  Install all required python modules, **run** $`pip3 install -r requirements.txt`
7.  If errors still occur install each python package in the `requirements.txt` file individually, **run** $`pip3 install [PACKAGE NAME]` ie $`pip3 install urllib3`.

## Setting Up a New ARTIS HPC on AWS 

The `initial_setup.py` script will create all necessary AWS infrastructure with terraform, upload all model inputs to an AWS S3 bucket `artis-s3-bucket`, and create and upload a docker image `artis-image` defaulted with files in `docker_image_files_original/` directory. These files allow the docker image to download all R scripts and model inputs from the `artis-s3-bucket/ARTIS_model_code/`. Anytime there are edits or changes to the ARTIS model codebase there is no need to recreate the docker image, skip to [Running an Existing ARTIS HPC Setup](#running-an-existing-artis-hpc-setup)

1.  **Open** Docker Desktop
2.  **Take note** of any existing docker images and containers relating to other projects, and **delete** all docker containers relating to ARTIS, **delete** all docker images relating to ARTIS.
3.  Create AWS infrastructure, upload model inputs, and create new ARTIS docker image, **run**:

``` sh
python3 initial_setup.py -chip [YOUR CHIP INFRASTRUCTURE] -aws_access_key [YOUR AWS KEY] -aws_secret_key [YOUR AWS SECRET KEY] -s3 artis-s3-bucket -ecr artis-image
```

  - Details:
    - If you are using an Apple Silicone chip (M1, M2, M3, etc) your chip will be `arm64`, otherwise for intel chips it will be `x86`
  - If you have an existing docker image you would like to use include the `-di [existing docker image name]` flag with the command shown below.
    - **Recommendation**: the default options will create a docker image called `artis-image`, so if you want to use the previously created default docker image you would include `-di artis-image`.
    - **Note:** The AWS docker image repository and the docker image created with default options both have the name `artis-image`, however they are two different resources.


``` sh
python3 initial_setup.py -chip [YOUR CHIP INFRASTRUCTURE] -aws_access_key [YOUR AWS KEY] -aws_secret_key [YOUR AWS SECRET KEY] -s3 artis-s3-bucket  -ecr artis-image -di artis-image:latest
```

**Example command** (using credentials stored in local environmental variables set above and creating the docker image from scratch):

``` sh
python3 initial_setup.py -chip arm64 -aws_access_key $AWS_ACCESS_KEY -aws_secret_key $AWS_SECRET_ACCESS_KEY -s3 artis-s3-bucket -ecr artis-image
```

**Note:** If terraform states that it created all resources however when you log into the AWS console to confirm cannot see them, they have most likely been created as part of another account. Run `terraform destroy -auto-approve` on the command line. Confirmed you have followed the AWS CLI set up instructions with the correct set of keys (AWS access key and AWS secret access key).

## Running an Existing ARTIS HPC Setup 

**Note:** All AWS infrastructure has already been created and there are only edits to the model input files or ARTIS model code.

-   Make sure to put all new R scripts or model inputs in the relevant `data_s3_upload` directory and **run**:

``` sh
python3 s3_upload.py
python3 submit_artis_jobs.py
```

*Check status of jobs submitted to AWS batch* 
-   navigate to AWS in your browser and log in to your IAM account.
-   Use the search bar at the top of the page to search for "batch" and click on the Service Batch result.
-   Under "job queue overview" you will be able to see job status. 

*Troubleshoot "failed" jobs*
-   Click on number below "failed" column of job queue
-   Identify and open relevant failed job. Inspect "Job attempts" for "status reason" value. 
-   Search for "cloudwatch" in search bar and click on the Service CloudWatch
-   In the left hand nav-bar click on "Logs"" then "Log groups" and next "/aws/batch/job"
-   Inspect "log stream" for timestamps and messages from running the model code. 

## Combine all ARTIS model outputs into database ready CSVs 

**run**
``` sh
python3 submit_combine_tables_job.py
```

# Download results, Clean up AWS and Docker environments 

1.  Download "outputs" folder from AWS, **run** $`python3 s3_download.py`
2.  Destroy all AWS resources and dependencies created, **run** $`terraform destroy`
3.  **Open** Docker Desktop app,
    4.  **Delete** all containers created
    5.  **Delete** all images created
6.  Close python environment, **run** $`deactivate`

## Create AWS IAM User

**FIXIT**: include screenshots for creating an IAM user with the correct admin permissions.
