## Docker container `artis-image` details

Once the docker image `artis-image` has been uploaded to AWS ECR, the docker container `artis-image` will need to import all R scripts and model inputs from the `artis-s3-bucket` on AWS. Once $`python3 submit_artis_jobs.py` is run, a new job on AWS Batch will run ARTIS on a new instance of the docker container for each HS version specified within each job. Each docker instance will only import the scripts and model inputs for the HS version and years it is running from `artis-s3-bucket` (occurs when `docker_image_artis_pkg_download.R` is sourced in `job_shell_scripts/`).

Example directory structure within `artis-image`:

```sh

/home/ec2-user/artis/
│
├── clean_fao_prod.csv
├── clean_fao_taxa.csv
├── clean_sau_prod.csv
├── clean_sau_taxa.csv
├── clean_taxa combined.csv
├── code_max_resolved.csv
├── fao_annual_pop.csv
├── hs-hs-match_HS[VERSION].csv (one file per each HS version)
├── hs-taxa-CF_strict-match_HS[VERSION].csv 
├── hs-taxa-match_HS[VERSION].csv
├── standardized_baci_seafood_hs[VERSION]_y[YEAR]_including_value.csv (one file per HS version/year combination)
├── standardized_baci_seafood_hs[VERSION]_y[YEAR].csv (one file per HS version/year combination)
├── standardized_combined_prod.csv
├── standardized_fao_prod.csv
├── standardized_sau_taxa.csv
│
│(Files pulled from `ARTIS_model_code/` in `artis-s3-bucket`. Folder not retained)
├── 00-aws-hpc-setup_hs[VERSION].R
├── 02-artis-pipeline_hs[VERSION].R
├── 03-combine-tables.R
├── NAMESPACE
├── DESCRIPTION
└── R/
    ├── build_artis_data.R
    ├── calculate_consumption.R
    ├── categorize_hs_to_taxa.R
    ├── classify_prod_dat.R
    ├── clean_fb_slb_synonyms.R
    ├── clean_hs.R
    ├── collect_data.R
    ├── compile_cf.R
    ├── create_export_source_weights.R
    ├── create_reweight_W_long.R
    ├── create_reweight_X_long.R
    ├── create_snet.R
    └── (Add all files)

```