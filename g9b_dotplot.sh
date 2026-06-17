#!/bin/bash
#SBATCH --job-name=g9b_dotplot
#SBATCH --output=g9b_dotplot_%j.log
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --time=4:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate base

minimap2 -x asm5 -t 32 \
    $REF_GENOME \
    $RAGTAG_OUT/ragtag.scaffold.fasta \
    > $RAGTAG_OUT/scaffold_vs_${REF_NAME}.paf

echo "--- Dotplot PAF complete ---"
echo "Output: $RAGTAG_OUT/scaffold_vs_${REF_NAME}.paf"
