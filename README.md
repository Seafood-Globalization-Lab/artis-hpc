# ARTIS HPC

This repository outlines the instructions and scripts needed to create the ARTIS High Performance Computer (HPC) on Amazon Web Services (AWS) and run the ARTIS model. There are two scenarios for using this repository:

-   Running a new version of ARTIS (updated code)
-   Rerunning a version of ARTIS (use an already created Docker image)

## Technologies used

-   Terraform
    -   This is a set of code scripts that create all the AWS infrastructure needed for the ARTIS HPC
    -   Destroy all AWS infrastructure for the ARTIS HPC after the ARTIS model has finished (save on unnecessary costs)
-   Docker
    -   This is used to create a docker image that our HPC jobs will use to run the ARTIS model code
-   Python
    -   Through the docker and AWS python (boto3) clients, this will provide code that:
        -   Push all model input data to AWS S3
        -   Build docker image needed that the AWS Batch jobs will need to run ARTIS model
        -   Push docker image to AWS ECR
        -   Submit jobs to ARTIS HPC
        -   Pull all model outputs data

## Update ARTIS model scripts and model inputs

1.  Copy the most up-to-date set of model inputs to the directory `artis-hpc/data_s3_upload`
2.  Copy the most up-to-date ARTIS R package folder and place within `artis-hpc/data_s3_upload/ARTIS_model_code`
3.  Copy the most up-to-date ARTIS R package NAMESPACE file and place within `artis-hpc/data_s3_upload/ARTIS_model_code`
4.  Copy the most up-to-date ARTIS R package DESCRIPTION file and place within `artis-hpc/data_s3_upload/ARTIS_model_code`
5.  Copy the most up-to-date .Renviron file and place within `artis-hpc/data_s3_upload/ARTIS_model_code`

If running on a new Apple chip arm64:

1.  Copy arm64_venv_requirements.txt file from the root directory to the `artis-hpc/docker_image_files_original/`
2.  Rename the file `artis-hpc/docker_image_files_original/arm64_venv_requirements.txt` to `artis-hpc/docker_image_files_original/requirements.txt`

## Installation

-   Homebrew
-   AWS CLI
-   Terraform CLI
-   Python
    -   Python packages
        -   docker
        -   boto3

### Homebrew installation

1.  Install homebrew by running the terminal command `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
2.  Close existing terminal window where installation command was run and open a new terminal window
3.  Confirm homebrew has been installed, run terminal command `brew --version`, no error messsage should appear.

*If after homebrew installation you get a message stating* `brew command not found`:

4.  Edit zsh config file, run terminal command: `vim ~/.zshrc`
5.  Type `i` to enter edit mode
6.  Copy paste this line into the file you opened: `export PATH=/opt/homebrew/bin:$PATH`
7.  Press Shift and :
8.  Type `wq`
9.  Press enter
10. Source new config file, run terminal command `source ~/.zshrc`

### AWS CLI installation

[Following instructions from AWS](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

**Note**: If you already have AWS CLI installed please still confirm by following step 3 below. Both instructions should run without an error message.

The following instructions are for MacOS users:

1.  Run terminal command `curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"`
2.  Run terminal command `sudo installer -pkg AWSCLIV2.pkg -target /`
3.  Confirm AWS CLI has been installed:
    1.  Run terminal command `which aws`
    2.  Run terminal command `aws --version`

### Terraform CLI installation

**Note**: If you already have homebrew installed please confirm by running `brew --version`, no error message should occur.

To install terraform on MacOS we will be using homebrew. If you do not have homebrew installed on your computer please follow the installation instructions [here](https://brew.sh/), before continuing.

Based on Terraform CLI installation instructions provided [here](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

1.  Run terminal command `brew tap hashicorp/tap`
2.  Run terminal command `brew install hashicorp/tap/terraform`
3.  Run terminal command `brew update`
4.  Run terminal command `brew upgrade hashicorp/tap/terraform`

If this has been unsuccessful you might need to install xcode command line tools, try:

5.  Run terminal command: `sudo xcode-select --install`

## Assumptions:

-   An AWS root user was created (To create an AWS root user visit [ ](aws.amazon.com))
-   AWS root user has created an admin user group with "AdministratorAccess" permissions.
-   AWS root user has created IAM users
-   AWS root user has add IAM users to admin group
-   AWS IAM users have their `AWS AWS_ACCESS_KEY` and `AWS_SECRET_ACCESS_KEY`

To create an AWS IAM user: - **FIXIT**: include screenshots for creating an IAM user with the correct admin permissions.

**Note**: If you created ANY AWS RESOURCES for ARTIS manually please delete these before continuing **(ASIDE FROM ROOT AND IAM USERS)**.

## AWS CLI Setup

1.  Run terminal command: `export AWS_ACCESS_KEY=[YOUR_AWS_ACCESS_KEY]`
    -   sets terminal environmental variable. Replace `[YOUR_AWS_ACCESS_KEY]` with your value
2.  Run terminal command: `export AWS_SECRET_ACCESS_KEY=[YOUR_AWS_SECRET_ACCESS_KEY]`
    -   sets terminal environmental variable. Replace `[AWS_SECRET_ACCESS_KEY]` with your value
3.  Run terminal command: `export AWS_REGION=us-east-1`
    -   sets terminal environmental variable
4.  Run terminal command `aws configure set aws_access_key_id $AWS_ACCESS_KEY`
    -   writes value to AWS credentials file (`~/.aws/credentials`)
5.  Run terminal command `aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY`
    -   writes value to AWS credentials file (`~/.aws/credentials`)
6.  Run terminal command `aws configure set region $AWS_REGION`
    -   writes value to AWS config file (`~/.aws/config`)

## Clear Existing AWS Resources

[Log onto AWS](https://us-east-2.signin.aws.amazon.com/oauth?client_id=arn%3Aaws%3Asignin%3A%3A%3Aconsole%2Fcanvas&code_challenge=8nUzqNmFpMsGqg4WwTqUKFyBdVu_t_hDZMOyRX_xuoY&code_challenge_method=SHA-256&response_type=code&redirect_uri=https%3A%2F%2Fconsole.aws.amazon.com%2Fconsole%2Fhome%3FhashArgs%3D%2523%26isauthcode%3Dtrue%26nc2%3Dh_ct%26oauthStart%3D1722978779160%26src%3Dheader-signin%26state%3DhashArgsFromTB_us-east-2_2ce942407ff08169) to check if there are any model outputs that need to be retained.

## Python Installation

In order to run `initial_setup.py` we need to create a virtual environment to run the script in. **Note**: Please make sure that your terminal is currently in your working directory that should end in `artis-hpc`, by running the terminal command `pwd`.

1.  Create a virtual environment, run terminal command:`python3 -m venv venv`
2.  Open virtual environment, run terminal command: `source venv/bin/activate`
3.  Install all required python modules, run terminal command: `pip3 install -r requirements.txt`
4.  Check that all python modules have been downloaded, run terminal command `pip3 list` and check that all modules in the requirements.txt file are included.

If an error occurs please follow these instructions:

5.  Upgrade your version of pip by running terminal command: `pip install --upgrade pip`
6.  Install all required python modules, run terminal command: `pip3 install -r requirements.txt`
7.  If errors still occur install each python package in the requirements.txt file individually, run terminal command `pip3 install [PACKAGE NAME]` ie `pip3 install urllib3`.

## Creating AWS Infrastructure with a setup file

**Note**: the `initial_setup.py` script will create all necessary AWS infrastructure with terraform, upload all model inputs to an AWS S3 bucket, and create and upload a docker image defaulted with files in `docker_image_files_original/` directory. These files allow the docker image to download all R scripts and model inputs from the `artis-s3-bucket/ARTIS_model_code`. Anytime there are edits or changes to the ARTIS model codebase there is no need to recreate the docker image, you would only have to re-upload the local files in `data_s3_upload/ARTIS_model_code`. It will also submit jobs to the ARTIS HPC.

1.  Open Docker Desktop
2.  Take note of any existing docker images and containers relating to other projects, and delete all docker containers relating to ARTIS, delete all docker images relating to ARTIS.
3.  Create AWS infrastructure, upload model inputs, and create new ARTIS docker image, run terminal command:

``` default
python3 initial_setup.py -chip [YOUR CHIP INFRASTRUCTURE] -aws_access_key [YOUR AWS KEY] -aws_secret_key [YOUR AWS SECRET KEY] -s3 artis-s3-bucket -ecr artis-image
```

-   If you are using an Apple Silicone chip (M1, M2, M3, etc) your chip will be `arm64`, otherwise for intel chips it will be `x86`

-   If you have an existing docker image you would like to use include the `-di [existing docker image name]` with the command. Recommendation: the default options will create a docker image called `artis-image`, so if you want to use the previously created default docker image you would include `-di artis-image`.

**Note:** The AWS docker image repository and the docker image created with default options both have the name `artis-image`, however they are two different resources.

``` default
python3 initial_setup.py -chip [YOUR CHIP INFRASTRUCTURE] -aws_access_key [YOUR AWS KEY] -aws_secret_key [YOUR AWS SECRET KEY] -s3 artis-s3-bucket  -ecr artis-image -di artis-image:latest
```

**Examples**: - If you are creating the docker image from scratch:

``` default
python3 initial_setup.py -chip arm64 -aws_access_key $AWS_ACCESS_KEY -aws_secret_key $AWS_SECRET_ACCESS_KEY -s3 artis-s3-bucket -ecr artis-image
```

``` default
python3 initial_setup.py -chip arm64 -aws_access_key abc1234 -aws_secret_key secretabc1234 -s3 artis-s3-bucket -ecr artis-image
```

**Note:** If terraform states that it created all resources however when you log into the AWS console to confirm cannot see them, they have most likely been created as part of another account. Run `terraform destroy -auto-approve`on the command line. Confirmed you have followed the AWS CLI set up instructions with the correct set of keys (AWS access key and AWS secret access key).

## Uploading new model inputs or ARTIS model code
**Note:** All AWS infrastructure has already been created and there are only edits to the model input files or ARTIS model code.

-   Make sure to put all new R scripts or model inputs in the relevant `data_s3_upload` directory and run:

``` default
python3 s3_upload.py
python3 submit_artis_jobs.py
```

## Combining all ARTIS model outputs into database ready CSVs

```default
python3 submit_combine_tables_job.py
```

# Download results, Clean up AWS and Docker environments

1.  Download "outputs" folder from AWS, run terminal command `python3 s3_download.py`
2.  Destroy all AWS resources and dependencies created, run terminal command `terraform destroy`
3.  Open Docker Desktop app and delete all containers created
4.  Open Docker Desktop app and delete all images created
5.  Close python environment, run terminal command: `deactivate`
