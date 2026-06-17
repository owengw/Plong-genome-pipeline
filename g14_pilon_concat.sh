#!/bin/bash
#SBATCH --job-name=g14_pilon_concat
#SBATCH --output=g14_pilon_concat_%j.log
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=2:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh

echo "[$(date)] Concatenating Pilon outputs..."
> $PILON_FASTA

# Add individual chromosome fastas in size order
echo "[$(date)] Adding individual chromosome outputs..."
for scaffold in $(sort -k2 -rn $RAGTAG_OUT/ragtag.scaffold.fasta.fai | \
                  awk '{print $1}'); do
    f=$PILON_OUT/by_chr/${scaffold}_pilon.fasta
    if [ -f "$f" ]; then
        cat $f >> $PILON_FASTA
        echo "  Added: $scaffold"
    fi
done

# Add all batch outputs directly - no sequence extraction needed
echo "[$(date)] Adding batch outputs..."
for batch_f in $(ls $PILON_OUT/by_chr/batch_*_pilon.fasta 2>/dev/null | sort); do
    echo "  Adding: $(basename $batch_f) ($(grep -c '>' $batch_f) sequences)"
    cat $batch_f >> $PILON_FASTA
done

# Regenerate fai
echo "[$(date)] Indexing..."
conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen
samtools faidx $PILON_FASTA

echo "[$(date)] Done: $PILON_FASTA"
grep -c "^>" $PILON_FASTA
awk '{sum+=$2} END{printf "Total: %.2f Gb, Scaffolds: %d\n", sum/1e9, NR}' \
    $PILON_FASTA.fai
ls -lh $PILON_FASTA