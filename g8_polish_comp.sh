#!/bin/bash

#SBATCH --job-name=g8_polish_comp
#SBATCH --output=g8_polish_comp.log
#SBATCH --mem=251G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=96:00:00

source ~/.bash_profile
conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen

src=$PWD

quast -o $src/genome/quast_25/quast_polish -t 16 --labels flye_nanopore_polish  -r $src/genome/flye_25/assembly.fasta $src/genome/medaka/consensus.fasta

busco -i $src/genome/medaka/consensus.fasta -o $src/genome/busco_25/polish_busco -m genome -l squamata_odb12 -c 16 -f