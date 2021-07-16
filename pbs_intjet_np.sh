#!/bin/bash -l
#PBS -A UMCP0012
#PBS -N I3d_CIjet01
#PBS -k eod
#PBS -o logs/I3d_CIjet01.out
#PBS -e logs/I3d_CIjet01.err
#PBS -l walltime=24:00:00
#PBS -q casper
#PBS -l select=1:ncpus=1:ngpus=1
#PBS -l gpu_type=v100
#PBS -M tchor@umd.edu
#PBS -m abe

# Clear the environment from any previously loaded modules
module purge
module load gnu
module load cuda/11.0.3
module load peak_memusage

#/glade/u/apps/ch/opt/usr/bin/dumpenv # Dumps environment (for debugging with CISL support)

export JULIA_DEPOT_PATH="/glade/work/tomasc/.julia_bkp"

peak_memusage.exe /glade/u/home/tomasc/repos/julia_1.5.2/julia --project \
    intjet_np.jl --fullname=I3d_CIjet01 --arch=GPU --factor=1 2>&1 | tee out/I3d_CIjet01.out
