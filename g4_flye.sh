#!/bin/bash

#SBATCH --job-name=g4_flye
#SBATCH --output=g4_flye.log
#SBATCH --mem=251G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=96:00:00

source ~/.bash_profile
conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen

src=$PWD
mkdir=$src/genome/flye_25

flye --nano-raw $src/genome/chopper/*_trimmed_15.fastq.gz --genome-size 1500m --out-dir $src/genome/flye_25 --threads 16
