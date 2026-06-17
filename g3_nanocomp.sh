#!/bin/bash

#SBATCH --job-name=g3_nanocomp
#SBATCH --output=g3_nanocomp.log
#SBATCH --mem=251G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=96:00:00

source ~/.bash_profile
conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen

src=$PWD


for f in $src/genome/raw/*$parameterF; 
do FBASE=$(basename $f)
	BASE=${FBASE%$parameterF}
  NanoComp -t 16 --fastq $f $src/genome/chopper/${BASE}_trimmed_15.fastq.gz --names Nanopore Nanopore_trim15 -o Skink_Nanocomp 
done

