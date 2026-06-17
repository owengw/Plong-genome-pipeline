#!/bin/bash
#SBATCH --job-name=g14_pilon_array
#SBATCH --output=g14_pilon_array_%a_%j.log
#SBATCH --mem=251G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=96:00:00
#SBATCH --array=1-20

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate /mnt/parscratch/users/bi4og/conda_envs/pilon

PILON_JAR=/mnt/parscratch/users/bi4og/conda_envs/pilon/share/pilon-1.24-0/pilon.jar
SUBSAMPLE_FRAC=0.08

mkdir -p $PILON_OUT/by_chr
mkdir -p $PILON_OUT/chr_bams

# Index assembly if needed
[ ! -f $RAGTAG_OUT/ragtag.scaffold.fasta.fai ] && \
    samtools faidx $RAGTAG_OUT/ragtag.scaffold.fasta

# Get all scaffolds sorted by size, split into 20 batches
TOTAL=$(wc -l < $RAGTAG_OUT/ragtag.scaffold.fasta.fai)
BATCH_SIZE=$(( (TOTAL + 19) / 20 ))  # ceiling division

# Get scaffolds for this array task
mapfile -t BATCH < <(sort -k2 -rn $RAGTAG_OUT/ragtag.scaffold.fasta.fai | \
    awk '{print $1}' | \
    awk -v task=$SLURM_ARRAY_TASK_ID \
        -v batch=$BATCH_SIZE \
        'NR > (task-1)*batch && NR <= task*batch')

echo "[$(date)] Array task $SLURM_ARRAY_TASK_ID: processing ${#BATCH[@]} scaffolds"
echo "[$(date)] First: ${BATCH[0]}, Last: ${BATCH[-1]}"

# Skip if all scaffolds in this batch already done
ALL_DONE=true
for TARGET in "${BATCH[@]}"; do
    if [ ! -f $PILON_OUT/by_chr/${TARGET}_pilon.fasta ]; then
        ALL_DONE=false
        break
    fi
done
if [ "$ALL_DONE" = true ]; then
    echo "[$(date)] All scaffolds in batch already polished, skipping"
    exit 0
fi

# Build targets string for scaffolds not yet done
TARGETS=""
for TARGET in "${BATCH[@]}"; do
    if [ ! -f $PILON_OUT/by_chr/${TARGET}_pilon.fasta ]; then
        TARGETS="${TARGETS},${TARGET}"
    fi
done
TARGETS="${TARGETS#,}"  # remove leading comma

echo "[$(date)] Targets to polish: $(echo $TARGETS | tr ',' '\n' | wc -l)"

# Extract reads for this batch
BATCH_BAM=$PILON_OUT/chr_bams/batch_${SLURM_ARRAY_TASK_ID}.bam
BATCH_SUB=$PILON_OUT/chr_bams/batch_${SLURM_ARRAY_TASK_ID}_sub.bam

if [ ! -f $BATCH_SUB ]; then
    echo "[$(date)] Extracting reads for batch $SLURM_ARRAY_TASK_ID..."
    REGIONS=$(echo $TARGETS | tr ',' ' ')
    samtools view -@ 8 -b -o $BATCH_BAM $MERGED_BAM $REGIONS
    samtools view -@ 8 -b -s $SUBSAMPLE_FRAC -o $BATCH_SUB $BATCH_BAM
    samtools index -@ 8 $BATCH_SUB
    rm -f $BATCH_BAM
fi

# Run Pilon on entire batch at once
echo "[$(date)] Running Pilon for batch $SLURM_ARRAY_TASK_ID..."
java -Xmx240g -jar $PILON_JAR \
    --genome $RAGTAG_OUT/ragtag.scaffold.fasta \
    --frags $BATCH_SUB \
    --output batch_${SLURM_ARRAY_TASK_ID}_pilon \
    --outdir $PILON_OUT/by_chr \
    --targets $TARGETS \
    --fix all \
    --mindepth 5 \
    --changes

echo "[$(date)] Pilon complete for batch $SLURM_ARRAY_TASK_ID"
rm -f $BATCH_SUB $BATCH_SUB.bai