# Changelog

All notable changes to **artis-hpc** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [1.1.0] – 2025-06-02

### Added
- **Restart‐at‐get_snet script** (`02-artis-pipeline-restart-snet-hs[hs-yr].R`):  
  - Creates option for model to run in chunks, useful if failures occur during the `get_snet` process.  
  - Locates `get_country_solutions()` combined output `*_all-country-est_<year>_HS<ver>.RDS` files from both “quadprog” and “cvxopt” solvers in S3 and imports them into the local Docker directory.  
  - Ensures that, once downloaded, `get_snet()` can proceed without re‐running the mass‐balance solver step in the main pipeline script.

- **Initial setup/restart helper** (`initial_setup_restart_snet.py`):  
  - Differs from the original `initial_setup.py` by focusing solely on configuring a restart path for `get_snet`, rather than full pipeline setup.  
  - Copies the appropriate Dockerfile (x86 vs. ARM64) into the project root for use with restart jobs.  
  - Injects AWS credentials (`AWS_ACCESS_KEY`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`) into both environment variables and the copied Dockerfile—unlike `initial_setup.py`, which assumed pre‐configured credentials.  
  - Propagates S3 bucket and ECR repository names into Terraform files (`main.tf` and `variables.tf`) for infrastructure provisioning used in restart scenarios.  
  - Updates R scripts inside the Docker context (under `docker_image_files`) with the correct `artis_bucket` S3 URL, whereas `initial_setup.py` did this only for the full pipeline.  
  - Optionally runs Terraform to provision AWS infrastructure, uploads model inputs to S3, builds and pushes the Docker image, and prepares for job submission—but omits resubmitting full ARTIS jobs to allow restart logic to take over.

- **Submit‐restart‐jobs script** (`submit_restart_artis_snet_jobs.py`):  
  - Reads `HS_VERSIONS` from the environment (e.g. `"02,07,12,17,96"`).  
  - For each HS version, submits an AWS Batch job that:  
    1. Uses the existing Docker image in ECR.  
    2. Inside the container, sources the baked‐in helper to pull all `ARTIS_model_code/` from S3.  
    3. Sources the HS‐specific restart script (e.g. `02-artis-pipeline-restart-snet-hs96.R`) to resume `get_snet()`.  

### Changed
- **Directory‐creation logic** in `02-artis-pipeline-restart-snet-hs[hs-yr].R`:  
  - Now explicitly creates `outdir_quadprog/HS<ver>/<year>/` and `outdir_cvxopt/HS<ver>/<year>/` before any S3 download.  
  - Removed hard‐coded filename helper functions; uses `years <- df_years$analysis_year[df_years$HS_year == hs_version_run]` to generate the year list dynamically.

- **AWS download calls** in `02-artis-pipeline-restart-snet-hs[hs-yr].R`:  
  - Switched to using a single `aws.s3::save_object(object = <key>, …)` once exactly one key matches the `rds_pattern`.  
  - Added a `stop()` if more than one key matches; `warning()` if none match.

- **`unlink()` usage** in helper scripts:  
  - Replaced calls like `unlink(a, b)` with `unlink(c(a, b))` to avoid “invalid `recursive` argument” errors when deleting multiple files.

### Deprecated
- _None in this release._

### Removed
- _None in this release._

### Fixed
- **Consistent `rds_pattern`** between `get_snet.R` and `02-artis-pipeline-restart-snet-hs[hs-yr].R`:  
  ```r
  rds_pattern <- paste0(
    ".*_all-country-est_.*",   # any prefix + “_all-country-est_”
    analysis_year,             # “_<year>_”
    "_HS", HS_year_rep,        # “_HS<ver>”
    "\\.RDS$"
  )
