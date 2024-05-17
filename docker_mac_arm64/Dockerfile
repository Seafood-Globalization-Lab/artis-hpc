FROM ubuntu:latest
USER root

RUN apt-get update && apt-get install -y --no-install-recommends libcurl4-openssl-dev libssl-dev libfontconfig1-dev libxml2-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev
RUN apt-get install -y libgit2-dev
RUN apt-get install -y gfortran
RUN apt-get update && apt-get install -y --no-install-recommends build-essential r-base
RUN apt-get install libssl3
RUN apt-get install -y python3 python3-pip python3-setuptools python3-dev python3-full

RUN mkdir /usr/src/ARTIS
WORKDIR /usr/src/ARTIS
COPY docker_image_files/* .

RUN apt-get install -y libblas-dev  libopenblas-dev libatlas-base-dev libsuitesparse-dev
RUN apt-get install -y libdsdp-dev libfftw3-dev libglpk-dev libgsl-dev
ENV CPPFLAGS="-I/usr/include/suitesparse"

RUN python3 -m venv venv
RUN venv/bin/pip install -r requirements.txt
RUN venv/bin/pip install qpsolvers[cvxopt]

RUN apt-get install -y curl
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

RUN aws configure set aws_access_key_id "YOUR_ACCESS_KEY"
RUN aws configure set aws_secret_access_key "YOUR_SECRET_ACCESS_KEY"
USER root
RUN R -e "source('pipeline_setup.R')"
