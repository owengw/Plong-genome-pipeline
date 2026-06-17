#!/bin/bash
#SBATCH --job-name=g10_liftoff_annotate
#SBATCH --output=g10_liftoff_annotate_%j.log
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --time=24:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate /mnt/parscratch/users/bi4og/users/bi4og/conda_envs/liftoff

mkdir -p ${LIFTOFF_OUT}_scaffold
mkdir -p ${LIFTOFF_OUT}_scaffold_intermediate

liftoff \
    $RAGTAG_OUT/ragtag.scaffold.fasta \
    $REF_GENOME \
    -g $REF_GFF \
    -o ${LIFTOFF_OUT}_scaffold/Plongirostris_${REF_NAME}.gff3 \
    -u ${LIFTOFF_OUT}_scaffold/unmapped_features.txt \
    -p 32 \
    -dir ${LIFTOFF_OUT}_scaffold_intermediate

echo "--- Liftoff scaffold complete ---"
echo "Genes in reference:"
grep -P "\tgene\t" $REF_GFF | wc -l
echo "Genes lifted:"
grep -P "\tgene\t" ${LIFTOFF_OUT}_scaffold/Plongirostris_${REF_NAME}.gff3 | wc -l
echo "Unmapped:"
wc -l ${LIFTOFF_OUT}_scaffold/unmapped_features.txt
