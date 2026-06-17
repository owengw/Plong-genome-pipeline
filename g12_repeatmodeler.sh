#!/bin/bash
#SBATCH --job-name=g12_repeatmodeler
#SBATCH --output=g12_repeatmodeler.log
#SBATCH --mem=251G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --time=96:00:00

source ~/.bash_profile
conda activate /mnt/parscratch/users/bi4og/conda_envs/repeatmasker

src=$PWD

mkdir -p $src/repeatmodeler

# Build genome database for RepeatModeler
BuildDatabase \
    -name $src/repeatmodeler/plongirostris \
    $src/ragtag_output/ragtag.scaffold.fasta

# Run RepeatModeler to generate de novo repeat library
RepeatModeler \
    -database $src/repeatmodeler/plongirostris \
    -threads 60 \
    -LTRStruct \
    -dir $src/repeatmodeler

echo "--- RepeatModeler complete ---"
echo "De novo library:"
ls $src/repeatmodeler/plongirostris-families.fa