#!/bin/bash

#SBATCH --job-name=g7_polish
#SBATCH --output=g7_polish.log
#SBATCH --mem=251G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=96:00:00

source ~/.bash_profile
conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen

src=$PWD

mkdir $src/genome/medaka

for f in $src/genome/raw/*$parameterF; 
do FBASE=$(basename $f)
	BASE=${FBASE%$parameterF}
  medaka_consensus -i $f -d $src/genome/flye_25/assembly.fasta -o $src/genome/medaka -t 16
done