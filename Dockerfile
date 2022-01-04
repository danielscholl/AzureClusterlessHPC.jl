FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive 

# Required packages
RUN apt-get update && \
    apt-get install -y gfortran python3-pip && \
    apt-get install -y git wget vim htop hdf5-tools

# Install Azure Python SDKs
RUN pip3 install azure-batch==9.0.0 azure-common azure-storage-blob==1.3.1 azure-storage-queue==1.4.0

# Install Julia
RUN wget "https://julialang-s3.julialang.org/bin/linux/x64/1.6/julia-1.6.1-linux-x86_64.tar.gz" && \
    tar -xvzf julia-1.6.1-linux-x86_64.tar.gz && \
    rm -rf julia-1.6.1-linux-x86_64.tar.gz && \
    ln -s /julia-1.6.1/bin/julia /usr/local/bin/julia

# AzureClusterlessHPC
RUN julia -e 'import Pkg; Pkg.develop(url="https://github.com/danielscholl/AzureClusterlessHPC.jl");'
