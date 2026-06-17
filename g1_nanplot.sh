#!/bin/bash

#SBATCH --job-name=g1_nanoplot
#SBATCH --output=g1_nanoplot.log
#SBATCH --mem=251G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --time=96:00:00

source ~/.bash_profile
conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen

src=$PWD

for f in $src/genome/raw/*$parameterF; 
do NanoPlot -t 16 --fastq $f --loglength -o Nanopore_nanoplot --plots dot
done

for f in $src/genome/raw/*$parameterF; 
do nanoQC -o Nanopore_nanoQC $f
done