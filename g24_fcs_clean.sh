#!/bin/bash
#SBATCH --job-name=g24_fcs_clean
#SBATCH --output=g24_fcs_clean_%j.log
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --time=01:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen

# ============================================================
# g24_fcs_clean.sh
# Clean assembly based on NCBI FCS-GX contamination report
# FCS-GX run: Galaxy, v0.5.5, db 2023-01-24
# Run date: Mon Jun 8 17:39:40 2026
#
# Contamination found:
#   FIX:     chr3_RagTag_pilon:19411447-19412323 (877bp) - Mammaliicoccus sciuri
#   EXCLUDE: contig_13884_RagTag_pilon (20,783bp)        - Mammaliicoccus sciuri
#   EXCLUDE: contig_14260_RagTag_pilon (48,582bp)        - Oceanobacillus profundus phage
#   EXCLUDE: contig_15569_RagTag_pilon (6,822bp)         - Mammaliicoccus sciuri
#   EXCLUDE: contig_16203_RagTag_pilon (7,310bp)         - Mammaliicoccus sciuri
#   EXCLUDE: contig_18978_RagTag_pilon (3,172bp)         - Staphylococcus chromogenes
#
# All contaminants are bacterial skin microbiome or bacteriophage
# consistent with tissue sample contamination during ONT library prep
# Total contamination: 0.36% of assembly (agg-cvg from FCS report)
# ============================================================

FASTA=$SRC/pilon/plongirostris_pilon.fasta
OUT=$SRC/pilon/plongirostris_pilon_clean.fasta
OUTDIR=$SRC/pilon

echo "[$(date)] Starting FCS-GX contamination clean"
echo "Input:  $FASTA"
echo "Output: $OUT"

# Validate input exists
[ ! -f "$FASTA" ] && echo "ERROR: $FASTA not found" && exit 1

# Index if needed
[ ! -f "$FASTA.fai" ] && samtools faidx $FASTA

echo "[$(date)] Input assembly:"
echo "  Sequences: $(grep -c '>' $FASTA)"
awk '{sum+=$2} END{printf "  Total size: %.3f Gb\n", sum/1e9}' $FASTA.fai

# ============================================================
# STEP 1: Define contigs to exclude entirely
# ============================================================
cat > /tmp/fcs_exclude_contigs.txt << 'EOF'
contig_13884_RagTag_pilon
contig_14260_RagTag_pilon
contig_15569_RagTag_pilon
contig_16203_RagTag_pilon
contig_18978_RagTag_pilon
EOF

echo "[$(date)] Contigs to exclude: $(wc -l < /tmp/fcs_exclude_contigs.txt)"

# ============================================================
# STEP 2: Build list of sequences to keep (all except excluded
#         contigs and chr3 which needs fixing separately)
# ============================================================
grep ">" $FASTA | sed 's/>//' | \
    grep -v -Ff /tmp/fcs_exclude_contigs.txt | \
    grep -v "^chr3_RagTag_pilon$" \
    > /tmp/fcs_keep_seqs.txt

echo "[$(date)] Sequences to carry over unchanged: $(wc -l < /tmp/fcs_keep_seqs.txt)"

# ============================================================
# STEP 3: Extract unchanged sequences
# ============================================================
echo "[$(date)] Extracting clean sequences..."
samtools faidx $FASTA \
    $(cat /tmp/fcs_keep_seqs.txt | tr '\n' ' ') \
    > $OUT

# ============================================================
# STEP 4: Fix chr3 - mask contaminated region with Ns
# FCS action: FIX region 19411447-19412323 (1-based, inclusive)
# Convert to 0-based for Python: 19411446 to 19412323
# Region length: 877 bp
# ============================================================
echo "[$(date)] Fixing chr3 - masking contaminated region 19411447-19412323..."

# Extract chr3 sequence
samtools faidx $FASTA chr3_RagTag_pilon > /tmp/chr3_original.fa

# Mask region using awk (no python needed)
awk -v start=19411447 -v end=19412323 '
BEGIN { pos=0 }
/^>/ { print; next }
{
    line = $0
    len = length(line)
    result = ""
    for (i=1; i<=len; i++) {
        pos++
        if (pos >= start && pos <= end)
            result = result "N"
        else
            result = result substr(line, i, 1)
    }
    print result
}' /tmp/chr3_original.fa >> $OUT

rm -f /tmp/chr3_original.fa

# ============================================================
# STEP 5: Reindex and validate
# ============================================================
echo "[$(date)] Indexing cleaned assembly..."
samtools faidx $OUT

echo "[$(date)] Cleaned assembly stats:"
echo "  Sequences: $(grep -c '>' $OUT)"
awk '{sum+=$2} END{printf "  Total size: %.3f Gb\n", sum/1e9}' $OUT.fai

# Verify chr3 is present and correct length
CHR3_LEN=$(grep "^chr3_RagTag_pilon" $OUT.fai | awk '{print $2}')
echo "  chr3 length: $CHR3_LEN bp (expected: 224098967)"

# Verify excluded contigs are gone
echo "[$(date)] Verifying excluded contigs removed:"
for contig in contig_13884_RagTag_pilon contig_14260_RagTag_pilon \
              contig_15569_RagTag_pilon contig_16203_RagTag_pilon \
              contig_18978_RagTag_pilon; do
    if grep -q "^$contig$" $OUT.fai 2>/dev/null; then
        echo "  ERROR: $contig still present!"
    else
        echo "  OK: $contig excluded"
    fi
done

# ============================================================
# STEP 6: Summary
# ============================================================
ORIG_SEQS=$(grep -c '>' $FASTA)
CLEAN_SEQS=$(grep -c '>' $OUT)
REMOVED=$((ORIG_SEQS - CLEAN_SEQS))

echo ""
echo "=== FCS Clean Summary ==="
echo "Original sequences:  $ORIG_SEQS"
echo "Cleaned sequences:   $CLEAN_SEQS"
echo "Excluded contigs:    $REMOVED"
echo "Masked regions:      1 (877 bp on chr3)"
echo "Output: $OUT"
echo "[$(date)] g24_fcs_clean complete"