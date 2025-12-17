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

# Install R and its dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        r-base \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /usr/src/ARTIS

# Set working directory
WORKDIR /usr/src/ARTIS

# Install pak
RUN Rscript -e "install.packages('pak', repos='https://cloud.r-project.org')"

# Configure repositories with PPM snapshot first, CRAN as backup
RUN R -e "pak::repo_add(PPM = 'PPM@2025-10-15')" && \
    R -e "pak::repo_add(CRAN = 'https://cloud.r-project.org')"

# Install R packages from list
# RUN Rscript -e "pak::pkg_install(readLines('r-packages.txt'), ask = FALSE)"

# Install artis-model from GitHub
RUN Rscript -e "pak::pkg_install('Seafood-Globalization-Lab/artis-model@deploy-to-AWS', dependencies = TRUE)"

# Copy the requirements.in file first
COPY requirements.in /usr/src/ARTIS/

# Create virtual environment first, then use pypi-timemachine properly
RUN python3 -m venv venv && \
    venv/bin/pip install --upgrade pip && \
    venv/bin/pip install pypi-timemachine && \
    (venv/bin/python -m pypi_timemachine "2025-10-15" & \
    sleep 5 && \
    export PIP_INDEX_URL=http://localhost:8000/simple && \
    venv/bin/pip install -r requirements.in && \
    pkill -f "python -m pypi_timemachine")

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && \
    rm -rf awscliv2.zip aws/

# Example command to run ARTIS
#CMD ["bash", "-c", "source venv/bin/activate && python3 run_artis.py"]
# probably want CMD command to push to image repository (github?)