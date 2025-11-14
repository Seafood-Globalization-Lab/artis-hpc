#!/bin/bash

R -e "source('docker_image_artis_pkg_download.R')"
R -e "source('03-combine-tables.R')"
