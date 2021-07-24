#!/bin/bash

###################################################################################################
# DO NOT MODIFY!

# Switch to superuser and load module
sudo bash
pwd

# Install Julia
wget "https://julialang-s3.julialang.org/bin/linux/x64/1.6/julia-1.6.1-linux-x86_64.tar.gz"
tar -xvzf julia-1.6.1-linux-x86_64.tar.gz
rm -rf julia-1.6.1-linux-x86_64.tar.gz
ln -s /mnt/batch/tasks/startup/wd/julia-1.6.1/bin/julia /usr/local/bin/julia

# Install AzureClusterlessHPC
julia -e 'using Pkg; Pkg.add(url="https://github.com/microsoft/AzureClusterlessHPC.jl")'

###################################################################################################
# ADD USER PACKAGES HERE

# Install Julia packages
julia -e 'using Pkg; Pkg.add(["Flux", "Zygote", "Parameters", "CUDA", "MLDatasets", "MLDataPattern"])'

# Precompile
julia -e 'using Flux, Zygote, Parameters, CUDA, MLDatasets, MLDataPattern'


###################################################################################################
# DO NOT MODIFY!

# Make julia dir available for all users
chmod -R 777 /mnt/batch/tasks/startup/wd/.julia
