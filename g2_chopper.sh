#!/bin/bash

#SBATCH --job-name=g2_chopper
#SBATCH --output=g2_chopper.log
#SBATCH --mem=251G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=96:00:00

source ~/.bash_profile
conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen

src=$PWD

mkdir $src/genome/chopper

for f in $src/genome/raw/*$parameterF; 
do FBASE=$(basename $f)
	BASE=${FBASE%$parameterF}
  gunzip -c $f | chopper --threads 16 -q 15 -l 500 --headcrop 27 --tailcrop 38 | gzip > $src/genome/chopper/${BASE}_trimmed_15.fastq.gz #--contam $src/genome/contamadapters.fasta
done

for f in $src/genome/chopper/*$parameterF; 
do nanoQC -o $src/Nanopore_nanoQC/Nanopore_trimmed_nanoQC $f
done