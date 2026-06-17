#!/bin/bash
#SBATCH --job-name=g19_minimap2_synteny
#SBATCH --output=g19_minimap2_synteny_%j.log
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=12:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate base

# ============================================================
# ARGUMENTS
# Usage: sbatch g19_minimap2_synteny.sh <query_assembly> <output_prefix>
# Example (fasciatus-scaffolded):
#   sbatch g19_minimap2_synteny.sh \
#     /mnt/parscratch/users/bi4og/repeatmasker_polished/plongirostris_pilon.fasta.masked \
#     fasciatus
# Example (gilberti-scaffolded):
#   sbatch g19_minimap2_synteny.sh \
#     /mnt/parscratch/users/bi4og/repeatmasker_gilberti/plongirostris_pilon_gilberti.fasta.masked \
#     gilberti
# ============================================================

QUERY=${1:?"ERROR: provide query assembly as argument 1"}
PREFIX=${2:?"ERROR: provide output prefix as argument 2"}

[ ! -f "$QUERY" ] && echo "ERROR: $QUERY not found" && exit 1

src=/mnt/parscratch/users/bi4og
OUTDIR=$src/synteny/${PREFIX}
mkdir -p $OUTDIR

echo "Query assembly: $QUERY"
echo "Output prefix:  $PREFIX"
echo "Output dir:     $OUTDIR"

# P. longirostris vs P. gilberti
echo "--- Running minimap2: P. longirostris vs P. gilberti ---"
minimap2 -cx asm5 \
    --cs \
    -t 16 \
    $src/genome/Pgilberti.fna \
    $QUERY \
    > $OUTDIR/Plong_${PREFIX}_vs_Pgilberti.paf

# P. longirostris vs P. fasciatus
echo "--- Running minimap2: P. longirostris vs P. fasciatus ---"
minimap2 -cx asm5 \
    --cs \
    -t 16 \
    $src/genome/rPleFas1.1.fasta \
    $QUERY \
    > $OUTDIR/Plong_${PREFIX}_vs_Pfasciatus.paf

echo "--- Filtering to chromosome-level alignments ---"
awk '$1~/^chr|^JANXHV/ && $6~/^chr|^JANXHV/ && $10>1000' \
    $OUTDIR/Plong_${PREFIX}_vs_Pgilberti.paf \
    > $OUTDIR/Plong_${PREFIX}_vs_Pgilberti_chronly.paf

awk '$1~/^chr|^JANXHV/ && $10>1000' \
    $OUTDIR/Plong_${PREFIX}_vs_Pfasciatus.paf \
    > $OUTDIR/Plong_${PREFIX}_vs_Pfasciatus_chronly.paf

echo "--- Done ---"
echo "P. gilberti PAF lines:  $(wc -l < $OUTDIR/Plong_${PREFIX}_vs_Pgilberti.paf)"
echo "P. fasciatus PAF lines: $(wc -l < $OUTDIR/Plong_${PREFIX}_vs_Pfasciatus.paf)"
echo "Filtered gilberti:      $(wc -l < $OUTDIR/Plong_${PREFIX}_vs_Pgilberti_chronly.paf)"
echo "Filtered fasciatus:     $(wc -l < $OUTDIR/Plong_${PREFIX}_vs_Pfasciatus_chronly.paf)"
echo "Upload *_chronly.paf files to D-GENIES: https://dgenies.toulouse.inrae.fr"