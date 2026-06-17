#!/bin/bash
#SBATCH --job-name=g13_repeatmasker
#SBATCH --output=g13_repeatmasker.log
#SBATCH --mem=128G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --time=96:00:00

source ~/.bash_profile
conda activate /mnt/parscratch/users/bi4og/conda_envs/repeatmasker


src=/mnt/parscratch/users/bi4og

mkdir -p $src/repeatmasker

# Combine de novo library with Squamata Dfam library
cat $src/repeatmodeler/plongirostris-families.fa \
    $src/repeat_libraries/squamata_dfam.fa \
    > $src/repeat_libraries/combined_repeats.fa

# Run RepeatMasker with combined library
RepeatMasker \
    -lib $src/repeat_libraries/combined_repeats.fa \
    -xsmall \
    -pa 60 \
    -gff \
    -dir $src/repeatmasker \
    $src/ragtag_output/ragtag.scaffold.fasta

echo "--- RepeatMasker complete ---"
echo "Masked genome:"
ls $src/repeatmasker/*.masked

# Summary statistics
cat $src/repeatmasker/*.tbl