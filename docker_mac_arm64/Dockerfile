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

# Install R using RIG
RUN curl -fsSL https://repo.rig.sh/install.sh | sh
RUN rig add r-release

# Create application directory
RUN mkdir /usr/src/ARTIS
WORKDIR /usr/src/ARTIS
COPY docker_image_files_original/ ./

# Install R packages from r-packages.txt
COPY r-packages.txt .
RUN rig pkg install --file r-packages.txt

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