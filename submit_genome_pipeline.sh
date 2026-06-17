#!/bin/bash
# submit_genome_pipeline.sh
# Usage: bash submit_genome_pipeline.sh
# Edit genome_pipeline_config.sh before running

SCRIPTS=/mnt/parscratch/users/bi4og/scripts

# Source config just to read N_CHRS and REF_NAME for display
source $SCRIPTS/genome_pipeline_config.sh

echo "============================================"
echo "Submitting pipeline for reference: $REF_NAME"
echo "============================================"

JOB9=$(sbatch --parsable $SCRIPTS/g9_ragtag_scaffold.sh)
echo "g9  RagTag scaffold:      $JOB9"

JOB9B=$(sbatch --parsable --dependency=afterok:$JOB9 $SCRIPTS/g9b_dotplot.sh)
echo "g9b Dotplot:              $JOB9B"

JOB10=$(sbatch --parsable --dependency=afterok:$JOB9 $SCRIPTS/g10_liftoff_annotate.sh)
echo "g10 Liftoff scaffold:     $JOB10"

JOB11=$(sbatch --parsable --dependency=afterok:$JOB9 $SCRIPTS/g11_busco_quast.sh)
echo "g11 BUSCO/QUAST:          $JOB11"

if [ ! -f "$MERGED_BAM" ]; then
    JOB14_ALIGN=$(sbatch --parsable --dependency=afterok:$JOB9 $SCRIPTS/g14_pilon_align.sh)
    echo "g14 Pilon align:          $JOB14_ALIGN"
    ARRAY_DEP="afterok:$JOB14_ALIGN"
else
    echo "Reusing existing BAM:     $MERGED_BAM"
    ARRAY_DEP="afterok:$JOB9"
fi

JOB14=$(sbatch --parsable --dependency=$ARRAY_DEP --array=1-${N_CHRS} $SCRIPTS/g14_pilon_array.sh)
echo "g14 Pilon array:          $JOB14"

JOB14C=$(sbatch --parsable --dependency=afterok:$JOB14 $SCRIPTS/g14_pilon_concat.sh)
echo "g14 concat:               $JOB14C"

JOB15=$(sbatch --parsable --dependency=afterok:$JOB14C $SCRIPTS/g15_busco_quast_polished.sh)
echo "g15 BUSCO/QUAST polished: $JOB15"

JOB16=$(sbatch --parsable --dependency=afterok:$JOB14C $SCRIPTS/g16_repeatmasker_polished.sh)
echo "g16 RepeatMasker:         $JOB16"

JOB17=$(sbatch --parsable --dependency=afterok:$JOB16 $SCRIPTS/g17_liftoff_polished.sh)
echo "g17 Liftoff polished:     $JOB17"

echo "============================================"
echo "Monitor: squeue -u \$USER"
echo "Chain: $JOB9 -> $JOB14C -> $JOB16 -> $JOB17"
echo "============================================"