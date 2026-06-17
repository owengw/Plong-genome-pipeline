#!/bin/bash
#SBATCH --job-name=g14_pilon_align
#SBATCH --output=g14_pilon_align_%j.log
#SBATCH --mem=251G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --time=96:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate /mnt/parscratch/users/bi4og/conda_envs/pilon

mkdir -p $PILON_OUT/bam_temp

echo "[$(date)] Indexing assembly..."
bwa index -p $PILON_OUT/scaffold_index $RAGTAG_OUT/ragtag.scaffold.fasta

echo "[$(date)] Aligning read pairs..."
i=0
while IFS=$'\t' read -r R1 R2; do
    i=$((i+1))
    SAMPLE=$(basename $R1 _f_paired.fastq.gz)
    BAM=$PILON_OUT/bam_temp/${SAMPLE}.sorted.bam
    echo "[$(date)] Aligning pair $i: $SAMPLE"
    bwa mem -t 32 $PILON_OUT/scaffold_index $R1 $R2 | \
        samtools sort -@ 8 -m 2G -o $BAM -
    samtools index $BAM
done < $FOFN

echo "[$(date)] Merging BAMs..."
samtools merge -@ 32 -f $PILON_OUT/all_illumina_merged.bam \
    $PILON_OUT/bam_temp/*.sorted.bam
samtools index -@ 32 $PILON_OUT/all_illumina_merged.bam

rm -rf $PILON_OUT/bam_temp
echo "[$(date)] Alignment complete."
echo "Merged BAM: $PILON_OUT/all_illumina_merged.bam"
