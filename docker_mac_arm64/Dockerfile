FROM ubuntu:latest
USER root

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # R dependencies
    libcurl4-openssl-dev libssl-dev libfontconfig1-dev libxml2-dev \
    libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev \
    libtiff5-dev libjpeg-dev libgit2-dev gfortran build-essential r-base \
    # Python + dev tools
    python3 python3-pip python3-setuptools python3-dev python3-venv \
    # Math + optimization libs
    libblas-dev libopenblas-dev libatlas-base-dev libsuitesparse-dev \
    libdsdp-dev libfftw3-dev libglpk-dev libgsl-dev \
    # Other utilities
    curl unzip && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables for optimization libraries
ENV CPPFLAGS="-I/usr/include/suitesparse"

# Create application directory
RUN mkdir /usr/src/ARTIS
WORKDIR /usr/src/ARTIS
COPY docker_image_files/ ./

# Set up Python virtual environment and install packages
RUN python3 -m venv venv && \
    venv/bin/pip install --upgrade pip && \
    venv/bin/pip install -r requirements.txt && \
    venv/bin/pip install qpsolvers[cvxopt]

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && \
    rm -rf awscliv2.zip aws/

# Install R packages
RUN R -e "source('docker_image_r_pkg_installs.R')"
#CMD ["bash", "-c", "source venv/bin/activate && python3 run_artis.py"] # Example command to run ARTIS