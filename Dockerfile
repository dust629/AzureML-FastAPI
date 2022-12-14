# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

FROM mcr.microsoft.com/azureml/o16n-base/python-assets:20220331.v12 AS inferencing-assets



# Tag: cuda:11.1.1-devel-ubuntu20.04
# Env: CUDA_VERSION=11.1.1
# Env: NCCL_VERSION=2.8.4
# Env: CUDNN_VERSION=8.0.5.39

FROM nvidia/cuda:11.2.2-cudnn8-devel-ubuntu20.04

USER root:root

ENV com.nvidia.cuda.version $CUDA_VERSION
ENV com.nvidia.volumes.needed nvidia_driver
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND noninteractive
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
ENV NCCL_DEBUG=INFO
ENV HOROVOD_GPU_ALLREDUCE=NCCL
ENV http_proxy http://204.79.90.44:8080
ENV https_proxy http://204.79.90.44:8080

#Install Common Dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # SSH and RDMA
    libmlx4-1 \
    libmlx5-1 \
    librdmacm1 \
    libibverbs1 \
    libmthca1 \
    libdapl2 \
    dapl2-utils \
    openssh-client \
    openssh-server \
    redis \
    iproute2 && \
    # rdma-core dependencies
    apt-get install -y \
    udev \
    libudev-dev \
    libnl-3-dev \
    libnl-route-3-dev \
    gcc \
    ninja-build \
    pkg-config \
    valgrind \
    cython3 \
    python3-docutils \
    pandoc \
    dh-python \
    python3-dev && \
    # Others
    apt-get install -y \
    build-essential \
    bzip2 \
    libbz2-1.0 \
    systemd \
    git \
    wget \
    cpio \
	pciutils \
	libnuma-dev \
	ibutils \
	ibverbs-utils \ 
	rdmacm-utils \
	infiniband-diags \
	perftest \
	librdmacm-dev \
	libibverbs-dev \
    libsm6 \
    libxext6 \
    libssl1.1 \
    libxrender-dev \
    libglib2.0-0 \
    dh-make \
    libx11-dev \
    libgcrypt20 \
    binutils-multiarch \
    nginx \
    fuse && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Inference
# Copy logging utilities, nginx and rsyslog configuration files, IOT server binary, etc.
COPY --from=inferencing-assets /artifacts /var/
RUN /var/requirements/install_system_requirements.sh && \
    cp /var/configuration/rsyslog.conf /etc/rsyslog.conf && \
    cp /var/configuration/nginx.conf /etc/nginx/sites-available/app && \
    ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app && \
    rm -f /etc/nginx/sites-enabled/default
ENV SVDIR=/var/runit
ENV WORKER_TIMEOUT=300
EXPOSE 5001 8883 8888


# Conda Environment
ENV MINICONDA_VERSION py37_4.9.2
ENV PATH /opt/miniconda/bin:$PATH
RUN wget -qO /tmp/miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    bash /tmp/miniconda.sh -bf -p /opt/miniconda && \
    conda clean -ay && \
    rm -rf /opt/miniconda/pkgs && \
    rm /tmp/miniconda.sh && \
    find / -type d -name __pycache__ | xargs rm -rf

# file for pip to use proxy in conda:
COPY .condarc .

# run fastapi 
COPY main.py .

# Create the environment:
COPY azure_env.yml .
RUN conda env create -f azure_env.yml

# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "myenv", "/bin/bash", "-c"]

# Demonstrate the environment is activated:
RUN echo "Make sure fastAPI is installed:"
RUN python -c "from fastapi import FastAPI"

# The code to run when container is started:
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "myenv", "uvicorn" "main:app" "--host" "0.0.0.0" "--port" "6789"]



