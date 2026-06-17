#!/bin/bash
#SBATCH --job-name=g16_repeatmasker
#SBATCH --output=g16_repeatmasker_%j.log
#SBATCH --mem=128G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --time=96:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate /mnt/parscratch/users/bi4og/conda_envs/repeatmasker

mkdir -p $REPEATMASKER_OUT

RepeatMasker \
    -lib $REPEAT_LIB \
    -xsmall \
    -pa 64 \
    -gff \
    -dir $REPEATMASKER_OUT \
    $PILON_FASTA

echo "--- RepeatMasker complete ---"
cat $REPEATMASKER_OUT/*.tbl
