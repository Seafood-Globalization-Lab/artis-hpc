#!/bin/bash

R -e "source('docker_image_artis_pkg_download.R')"
R -e "source('02-artis-pipeline_hs12.R')"
