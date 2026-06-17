#!/bin/bash

#SBATCH --job-name=g5_quast
#SBATCH --output=g5_quast.log
#SBATCH --mem=251G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=96:00:00

source ~/.bash_profile
conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen

src=$PWD
mkdir $src/genome/quast_25

quast $src/genome/flye_25/assembly.fasta -o $src/genome/quast_25/quast_flye -t 16 --labels flye_nanopore -r $src/genome/flye_25/assembly.fasta