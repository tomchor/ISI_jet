#!/bin/bash -l
#PBS -A UMCP0012
#PBS -N i2CIjet01
#PBS -o logs/pbs.out
#PBS -e logs/%x.err
#PBS -l walltime=24:00:00
#PBS -q casper
#PBS -l select=1:ncpus=1:ngpus=1
#PBS -l gpu_type=v100
#PBS -M tchor@umd.edu
#PBS -m abe

# Clear the environment from any previously loaded modules
module purge
module load gnu
module load cuda

/glade/u/apps/ch/opt/usr/bin/dumpenv # Dumps environment (for debugging with CISL support)

/glade/u/home/tomasc/repos/julia/julia --project \
    intjet_2dnp.jl --jet=CIjet01 --arch=GPU --factor=1 2>&1 | tee logs/ij2d_CIjet01.out

