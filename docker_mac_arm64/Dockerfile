FROM ubuntu:latest
USER root

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        unzip \
        python3 \
        python3-pip \
        python3-setuptools \
        python3-dev \
        python3-venv \
        build-essential \
        libblas-dev \
        libopenblas-dev \
        libatlas-base-dev \
        libsuitesparse-dev \
        libgit2-dev \
        gfortran && \
    rm -rf /var/lib/apt/lists/*

# Install R (latest version)
RUN apt-get update && \
    apt-get install -y --no-install-recommends r-base && \
    rm -rf /var/lib/apt/lists/*

# Create application directory
RUN mkdir /usr/src/ARTIS
WORKDIR /usr/src/ARTIS
COPY docker_image_files_original/ ./

# Copy R package list
COPY docker_image_files_original/r-packages.txt .

# Install R and pak packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev && \
    rm -rf /var/lib/apt/lists/*

# Install pak
RUN Rscript -e "install.packages('pak', repos='https://cloud.r-project.org')"

# Configure repositories with PPM snapshot first, CRAN as backup
RUN R -e "pak::repo_add(PPM = 'PPM@2025-10-15')" && \
    R -e "pak::repo_add(CRAN = 'https://cloud.r-project.org')"

# Install R packages from list
RUN Rscript -e "pak::pkg_install(readLines('r-packages.txt'), ask = FALSE)"

# # Use CRAN mirror and install pak
# RUN Rscript -e "install.packages('pak', repos='https://cloud.r-project.org')" && \
#     Rscript -e "pak::pkg_install(readLines('r-packages.txt'), ask = FALSE)"

# Set up Python virtual environment and install packages
RUN python3 -m venv venv && \
    venv/bin/pip install --upgrade pip && \
    venv/bin/pip install -r requirements.txt && \
    venv/bin/pip install qpsolvers[cvxopt]

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && \
    rm -rf awscliv2.zip aws/

# Example command to run ARTIS
#CMD ["bash", "-c", "source venv/bin/activate && python3 run_artis.py"]