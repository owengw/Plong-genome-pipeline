#!/bin/bash
#SBATCH --job-name=g15_busco_quast_polished
#SBATCH --output=g15_busco_quast_polished_%j.log
#SBATCH --mem=128G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --time=24:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
export _JAVA_OPTIONS="-Xmx100g"

conda activate busco
busco \
    -i $PILON_FASTA \
    -o $BUSCO_POLISHED \
    -m genome \
    -l $BUSCO_LINEAGE \
    -c 32 \
    -f
conda deactivate

conda activate /mnt/parscratch/users/bi4og/users/bi4og/conda_envs/quast
quast \
    -o $QUAST_POLISHED \
    -r $REF_GENOME \
    -t 32 \
    --labels "flye_contigs,ragtag_${REF_NAME},polished_${REF_NAME}" \
    $MEDAKA \
    $RAGTAG_OUT/ragtag.scaffold.fasta \
    $PILON_FASTA

echo "--- g15 BUSCO/QUAST polished complete ---"
