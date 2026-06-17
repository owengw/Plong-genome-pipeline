#!/bin/bash
#SBATCH --job-name=g17_liftoff_polished
#SBATCH --output=g17_liftoff_polished_%j.log
#SBATCH --mem=128G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --time=24:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate /mnt/parscratch/users/bi4og/users/bi4og/conda_envs/liftoff

# Masked assembly from RepeatMasker
MASKED=$(ls ${REPEATMASKER_OUT}/*.masked | head -1)

mkdir -p $LIFTOFF_OUT
mkdir -p ${LIFTOFF_OUT}_intermediate

liftoff \
    $MASKED \
    $REF_GENOME \
    -g $REF_GFF \
    -o $LIFTOFF_OUT/Plongirostris_${REF_NAME}_polished.gff3 \
    -u $LIFTOFF_OUT/unmapped_features.txt \
    -p 32 \
    -dir ${LIFTOFF_OUT}_intermediate

echo "--- Liftoff polished complete ---"
echo "Genes in reference ($REF_NAME):"
grep -P "\tgene\t" $REF_GFF | wc -l
echo "Genes lifted to polished assembly:"
grep -P "\tgene\t" $LIFTOFF_OUT/Plongirostris_${REF_NAME}_polished.gff3 | wc -l
echo "Unmapped features:"
wc -l $LIFTOFF_OUT/unmapped_features.txt
