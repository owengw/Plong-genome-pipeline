#!/bin/bash

#SBATCH --job-name=g6_busco
#SBATCH --output=g6_busco.log
#SBATCH --mem=251G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=96:00:00

source ~/.bash_profile
conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen

src=$PWD
mkdir $src/genome/busco_25

busco -i $src/genome/flye_25/assembly.fasta -m genome -l squamata_odb12 -c 16 -o $src/genome/busco_25/BUSCO_plong -f