# 02-artis-pipeline_restart_get_snet.R
# script to restart AWS pipeline at get_snet() using existing s3 directories and 
# data. Used 2025-05-15 for ARTIS v1.1.0 SAU when all HS version jobs completed 
# country solutions and failed and exited when running get_snet() because of 
# missing file. "clean_fao_taxa.csv" read in was hardcoded.

rm(list=ls())

# Environment
run_env <- "aws"
hs_version_run <- "17"

source("00-aws-hpc-setup.R")


# Create docker container dirs --------------------------------------------

# general output folder
if(dir.exists(outdir)) {
  warning(glue::glue("`{outdir}/` folder already exists, all contents are being deleted to create an empty folder."))
  unlink(outdir, recursive = TRUE)
}
dir.create(outdir)

# sub output folder for quadprog solutions
if (dir.exists(outdir_quadprog)) {
  warning("quadprog output folder already exists, all contents are being deleted to create an empty folder.")
  unlink(outdir_quadprog, recursive = TRUE)
}
dir.create(outdir_quadprog)

# sub output folder for cvxopt solutions
if (dir.exists(outdir_cvxopt)) {
  warning("cvxopt output folder already exists, all contents are being deleted to create an empty folder.")
  unlink(outdir_cvxopt, recursive = TRUE)
}
dir.create(outdir_cvxopt)

# sub output folder for ARTIS snet results
if(dir.exists(outdir_snet)) {
  warning("ARTIS snet output folder already exists, all contents are being deleted to create an empty folder.")
  unlink(outdir_snet, recursive = TRUE)
}
dir.create(outdir_snet)

# create all HS and year child dirs

# 1) Reconstruct the df_years table exactly as in initial_variable_setup()
df_years <- data.frame(
  HS_year      = c(
    rep("96", length(1996:2020)),
    rep("02", length(2002:2020)),
    rep("07", length(2007:2020)),
    rep("12", length(2012:2020)),
    rep("17", length(2017:2020))
  ),
  analysis_year = c(
    1996:2020,
    2002:2020,
    2007:2020,
    2012:2020,
    2017:2020
  ),
  stringsAsFactors = FALSE
)

# 2) Pick out only the years for this HS version
years <- df_years$analysis_year[df_years$HS_year == hs_version_run]

# 3) Create exactly those subdirectories under quadprog and cvxopt
hs_dir <- paste0("HS", hs_version_run)

for (d in c(outdir_quadprog, outdir_cvxopt)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(d, hs_dir), recursive = TRUE, showWarnings = FALSE)
  for (yr in years) {
    dir.create(file.path(d, hs_dir, yr), recursive = TRUE, showWarnings = FALSE)
  }
}

# import s3 country solution data -----------------------------------------

for (solver_dir in c(outdir_quadprog, outdir_cvxopt)) {
  for (yr in years) {
    prefix <- file.path(solver_dir, hs_dir, yr)
    objs   <- aws.s3::get_bucket_df(bucket = artis_bucket,
                                    region = artis_bucket_region,
                                    prefix = prefix, max = Inf)
    
    keys <- objs$Key[grepl(
      paste0(".*_all-country-est_.*", yr, "_HS", hs_version_run, "\\.RDS$"),
      objs$Key
    )]
    
    if (length(keys) == 0) {
      warning("No all-country-est file under ", prefix)
      next
    }
    if (length(keys) > 1) {
      stop("Expected exactly one all-country-est under ", prefix,
           " but found: ", paste(basename(keys), collapse = ", "))
    }
    
    message("Downloading from s3: ", keys)
    aws.s3::save_object(
      object = keys,
      bucket = artis_bucket,
      region = artis_bucket_region,
      file   = keys
    )
  }
}

# restart pipeline at get_snet --------------------------------------------

# Takes all solutions of country mass balance problems and calculates ARTIS database
# records, along with corresponding consumption records

message("Starting `get_snet()`")

if (run_env == "aws") {
  get_snet(
    quadprog_dir = outdir_quadprog,
    cvxopt_dir = outdir_cvxopt,
    datadir = datadir,
    outdir = outdir_snet,
    num_cores = 3,
    hs_version = hs_version_run,
    test_years = test_years,
    prod_type = prod_data_type,
    estimate_type = "midpoint",
    run_env = "aws",
    s3_bucket_name = artis_bucket,
    s3_region = artis_bucket_region
  )
} else {
  get_snet(
    quadprog_dir = outdir_quadprog,
    cvxopt_dir = outdir_cvxopt,
    datadir = datadir,
    outdir = outdir_snet,
    num_cores = 1,
    hs_version = hs_version_run,
    test_years = test_years,
    prod_type = prod_data_type,
    estimate_type = "midpoint",
    run_env = "demo"
  )
}

message("Finished `get_snet()` and `02-artis-pipeline`")
