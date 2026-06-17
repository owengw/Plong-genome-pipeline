#!/bin/bash
#SBATCH --job-name=g27_make_sqn
#SBATCH --output=g27_make_sqn_%j.log
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --time=04:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen

# ============================================================
# g27_make_sqn.sh
# Convert final FASTA + GFF3 to .sqn for NCBI submission
#
# REQUIRES (must be prepared before running):
#   1. template.sbt - generated at https://submit.ncbi.nlm.nih.gov/genbank/template/submission/
#      (requires BioProject + BioSample accessions already registered)
#   2. final FASTA from g25
#   3. final GFF3 from g25
# ============================================================

TABLE2ASN=/mnt/parscratch/users/bi4og/tools/table2asn/table2asn
FASTA=$SRC/pilon/plongirostris_pilon_final.fasta
GFF=$SRC/liftoff_polished/Plestiodon_longirostris_polished_final.gff3
TEMPLATE=$SRC/ncbi_submission/template.sbt
OUTDIR=$SRC/ncbi_submission
CHR_TABLE=$SRC/ncbi_submission/chromosome_assignments.txt

mkdir -p $OUTDIR

echo "[$(date)] Starting .sqn generation"

# Check requirements
[ ! -f "$TABLE2ASN" ] && echo "ERROR: table2asn not found - run g26 first" && exit 1
[ ! -f "$FASTA" ]     && echo "ERROR: $FASTA not found - run g25 first" && exit 1
[ ! -f "$GFF" ]       && echo "ERROR: $GFF not found - run g25 first" && exit 1
[ ! -f "$TEMPLATE" ]  && echo "ERROR: $TEMPLATE not found
  Generate at: https://submit.ncbi.nlm.nih.gov/genbank/template/submission/
  Requires BioProject and BioSample accessions
  Save as: $TEMPLATE" && exit 1

# ============================================================
# STEP 1: Generate chromosome assignment table
# ============================================================
echo "[$(date)] Generating chromosome assignment table..."

grep ">" $FASTA | sed 's/>//' | \
    grep "^chr[0-9]*_RagTag_pilon$" | \
    sed 's/chr\([0-9]*\)_RagTag_pilon/&\t\1/' \
    > $CHR_TABLE

echo "Chromosome assignments:"
cat $CHR_TABLE

# ============================================================
# STEP 2: Copy FASTA into submission dir (table2asn expects
# matched basenames for .fsa and .gff)
# ============================================================
echo "[$(date)] Preparing input files..."

cp $FASTA $OUTDIR/plongirostris.fsa
cp $GFF   $OUTDIR/plongirostris.gff

# ============================================================
# STEP 3: Run table2asn
# -M n         : prokaryote/eukaryote normal mode
# -J           : correct intron/exon mismatches
# -c w         : fix whitespace in identifiers
# -euk         : eukaryote (affects gene model checks)
# -gaps-min 10 : minimum gap size to report (matches NCBI form)
# -gaps-unknown 100 : treat 100bp gaps as unknown-length
# -j           : organism source qualifiers
# ============================================================
echo "[$(date)] Running table2asn..."

cd $OUTDIR

$TABLE2ASN \
    -i plongirostris.fsa \
    -f plongirostris.gff \
    -t $TEMPLATE \
    -M n \
    -euk \
    -J \
    -c w \
    -gaps-min 10 \
    -gaps-unknown 100 \
    -chromosomes $CHR_TABLE \
    -j "[organism=Plestiodon longirostris] [tech=wgs]" \
    -o plongirostris_longirostris.sqn \
    -Z plongirostris_discrepancy_report.txt \
    -V vb

EXIT_CODE=$?

# ============================================================
# STEP 4: Check output
# ============================================================
echo ""
echo "=== table2asn output ==="
ls -la $OUTDIR/*.sqn $OUTDIR/*.val $OUTDIR/*discrepancy* 2>/dev/null

if [ -f "$OUTDIR/plongirostris_longirostris.sqn" ]; then
    echo ""
    echo "STATUS: .sqn file generated successfully"
    echo "File: $OUTDIR/plongirostris_longirostris.sqn"
else
    echo ""
    echo "STATUS: FAILED - no .sqn file generated (exit code $EXIT_CODE)"
fi

# Check validation errors
if [ -f "$OUTDIR/plongirostris.val" ]; then
    echo ""
    echo "=== Validation summary ==="
    grep -c "ERROR" $OUTDIR/plongirostris.val 2>/dev/null | \
        xargs -I{} echo "Errors: {}"
    grep -c "WARNING" $OUTDIR/plongirostris.val 2>/dev/null | \
        xargs -I{} echo "Warnings: {}"
    echo ""
    echo "First 20 errors/warnings:"
    grep -E "ERROR|WARNING" $OUTDIR/plongirostris.val | head -20
fi

echo "[$(date)] g27_make_sqn complete"