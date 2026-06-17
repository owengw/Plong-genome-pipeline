#!/bin/bash
#SBATCH --job-name=g9_ragtag_scaffold
#SBATCH --output=g9_ragtag_scaffold_%j.log
#SBATCH --mem=251G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --time=24:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate /mnt/parscratch/users/bi4og/users/bi4og/conda_envs/ragtag

mkdir -p $RAGTAG_OUT

ragtag.py scaffold \
    $REF_GENOME \
    $MEDAKA \
    -o $RAGTAG_OUT \
    -t 32 \
    -u \
    -q 10

echo "--- RagTag Scaffold complete ---"
echo "Reference: $REF_GENOME"
echo "Output: $RAGTAG_OUT"
echo "Number of scaffolds:"
grep -c ">" $RAGTAG_OUT/ragtag.scaffold.fasta
