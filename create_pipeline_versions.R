# Get the HS versions defined in .Renviron file
hs_versions <- strsplit(Sys.getenv("HS_VERSIONS"), ",")[[1]]

# Read the original script
original_script <- readLines(file.path("data_s3_upload",
                                        "ARTIS_model_code",
                                        "02-artis-pipeline.R"))

# Loop through each HS version and create a new script
for (hs_version in hs_versions) {
  # Modify the relevant line
  modified_script <- original_script
  modified_script[29] <- paste0('hs_version_run <- "', hs_version, '"')
  
  # Define the new file name
  new_file_name <- file.path("data_s3_upload", 
                             "ARTIS_model_code", 
                             paste0("02-artis-pipeline-hs", 
                                    hs_version, 
                                    ".R"))
  
  # Write the modified script to a new file
  writeLines(modified_script, new_file_name)
}

# Print a message to confirm the process is done
print("All HS version pipeline scripts have been created")
