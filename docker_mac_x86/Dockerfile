FROM rocker/tidyverse
# taken from: https://github.com/hengweiliu2020/create-docker-image-for-R-shiny-app-that-calls-python-scritpt/blob/main/Dockerfile
RUN apt-get update && apt-get install --no-install-recommends -y \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    # libssl1.1 \
    && rm -rf /var/lib/apt/lists/*

# system library dependency for the ae app
RUN apt-get update && apt-get install -y \
    libmpfr-dev \
    && rm -rf /var/lib/apt/lists/*
    
# miniconda
ENV PATH="/root/miniconda3/bin:${PATH}"
ARG PATH="/root/miniconda3/bin:${PATH}"
RUN apt-get update

RUN apt-get install -y wget && rm -rf /var/lib/apt/lists/*

RUN wget \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && mkdir /root/.conda \
    && bash Miniconda3-latest-Linux-x86_64.sh -b \
    && rm -f Miniconda3-latest-Linux-x86_64.sh 
RUN conda --version

RUN pip install pandas
RUN pip install numpy
RUN pip install scipy
RUN pip install qpsolvers
RUN pip install qpsolvers[quadprog]
RUN pip install qpsolvers[cvxopt]
RUN pip --no-cache-dir install --upgrade awscli

#RUN sudo useradd -ms /bin/bash artis
#RUN adduser artis sudo
#USER artis

RUN mkdir /usr/src/ARTIS
WORKDIR /usr/src/ARTIS
# WORKDIR /home/artis
COPY docker_image_files/ .

RUN aws configure set aws_access_key_id "YOUR_ACCESS_KEY"
RUN aws configure set aws_secret_access_key "YOUR_SECRET_ACCESS_KEY"
USER root
RUN R -e "source('pipeline_setup.R')"

