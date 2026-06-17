#!/bin/bash
#SBATCH --job-name=g25_ncbi_prep
#SBATCH --output=g25_ncbi_prep_%j.log
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --time=02:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen

# ============================================================
# g25_ncbi_prep.sh
# Final assembly preparation for NCBI submission
# Runs after g24_fcs_clean.sh
#
# Steps:
#   1. Remove sequences <200bp
#   2. Check and report gap (N-run) statistics
#   3. Remove sequences with excessive Ns (>50% N content)
#   4. Final validation checks
#   5. Clean GFF3 to match final FASTA
# ============================================================

CLEAN=$SRC/pilon/plongirostris_pilon_clean.fasta
FINAL=$SRC/pilon/plongirostris_pilon_final.fasta
GFF_CLEAN=$SRC/liftoff_polished/Plestiodon_longirostris_polished_clean.gff3
GFF_FINAL=$SRC/liftoff_polished/Plestiodon_longirostris_polished_final.gff3

echo "[$(date)] Starting NCBI preparation"
echo "Input FASTA: $CLEAN"
echo "Input GFF3:  $GFF_CLEAN"

[ ! -f "$CLEAN" ]     && echo "ERROR: $CLEAN not found — run g24 first" && exit 1
[ ! -f "$GFF_CLEAN" ] && echo "ERROR: $GFF_CLEAN not found" && exit 1

# Index if needed
[ ! -f "$CLEAN.fai" ] && samtools faidx $CLEAN

echo ""
echo "=== Input assembly ==="
echo "Sequences: $(grep -c '>' $CLEAN)"
awk '{sum+=$2} END{printf "Total size: %.3f Gb\n", sum/1e9}' $CLEAN.fai

# ============================================================
# STEP 1: Remove sequences <200bp
# NCBI hard requirement - all sequences must be >=200bp
# ============================================================
echo ""
echo "=== STEP 1: Remove sequences <200bp ==="

awk '$2<200{print $1}' $CLEAN.fai > /tmp/ncbi_short_seqs.txt
SHORT_COUNT=$(wc -l < /tmp/ncbi_short_seqs.txt)
echo "Sequences <200bp: $SHORT_COUNT"

if [ $SHORT_COUNT -gt 0 ]; then
    echo "Removing:"
    awk '$2<200{print "  "$1, $2"bp"}' $CLEAN.fai
fi

# ============================================================
# STEP 2: Check gap (N-run) statistics per sequence
# Report sequences with >50% N content for removal
# ============================================================
echo ""
echo "=== STEP 2: Gap (N-run) analysis ==="

awk '
/^>/ {
    if (seq != "" && chr != "") {
        # Count Ns
        n_count = 0
        tmp = seq
        while (match(tmp, /[Nn]+/)) {
            run_len = RLENGTH
            n_count += run_len
            if (run_len > max_gap) max_gap = run_len
            gap_count++
            tmp = substr(tmp, RSTART + RLENGTH)
        }
        pct_n = (length(seq) > 0) ? n_count/length(seq)*100 : 0
        print chr, length(seq), n_count, pct_n, gap_count, max_gap
    }
    chr = substr($0, 2)
    seq = ""
    max_gap = 0
    gap_count = 0
    next
}
{ seq = seq $0 }
END {
    if (seq != "" && chr != "") {
        n_count = 0
        tmp = seq
        while (match(tmp, /[Nn]+/)) {
            run_len = RLENGTH
            n_count += run_len
            if (run_len > max_gap) max_gap = run_len
            gap_count++
            tmp = substr(tmp, RSTART + RLENGTH)
        }
        pct_n = (length(seq) > 0) ? n_count/length(seq)*100 : 0
        print chr, length(seq), n_count, pct_n, gap_count, max_gap
    }
}' $CLEAN > /tmp/ncbi_gap_stats.txt

echo "Gap statistics across all sequences:"
awk '
BEGIN {
    total_gaps=0; total_seqs=0; max_gap=0; high_n=0
}
{
    total_seqs++
    total_gaps += $5
    if ($6 > max_gap) max_gap = $6
    if ($4 > 50) high_n++
}
END {
    printf "  Total sequences analysed: %d\n", total_seqs
    printf "  Total gap runs:           %d\n", total_gaps
    printf "  Largest single gap:       %d bp\n", max_gap
    printf "  Sequences >50%% N:         %d\n", high_n
}' /tmp/ncbi_gap_stats.txt

# List sequences with >50% N content
echo ""
echo "Sequences with >50% N content (will be removed):"
awk '$4>50{printf "  %-40s len=%-10d pct_N=%.1f%%\n", $1, $2, $4}' \
    /tmp/ncbi_gap_stats.txt | head -20

awk '$4>50{print $1}' /tmp/ncbi_gap_stats.txt \
    > /tmp/ncbi_high_n_seqs.txt
HIGH_N_COUNT=$(wc -l < /tmp/ncbi_high_n_seqs.txt)
echo "  Total to remove: $HIGH_N_COUNT"

# Also flag sequences with very large gaps (>100kb) for information
echo ""
echo "Sequences with gaps >100kb (informational only):"
awk '$6>100000{printf "  %-40s max_gap=%d bp\n", $1, $6}' \
    /tmp/ncbi_gap_stats.txt | head -10
LARGE_GAP=$(awk '$6>100000' /tmp/ncbi_gap_stats.txt | wc -l)
echo "  Total: $LARGE_GAP"

# ============================================================
# STEP 3: Build final keep list and generate clean FASTA
# Removes: sequences <200bp AND sequences >50% N
# ============================================================
echo ""
echo "=== STEP 3: Generating final FASTA ==="

# Combine exclusion lists
cat /tmp/ncbi_short_seqs.txt /tmp/ncbi_high_n_seqs.txt | \
    sort -u > /tmp/ncbi_all_exclude.txt

TOTAL_REMOVE=$(wc -l < /tmp/ncbi_all_exclude.txt)
echo "Total sequences to remove: $TOTAL_REMOVE"
echo "  - Short (<200bp):   $SHORT_COUNT"
echo "  - High N (>50%):    $HIGH_N_COUNT"

# Build keep list
grep ">" $CLEAN | sed 's/>//' | \
    grep -v -Ff /tmp/ncbi_all_exclude.txt \
    > /tmp/ncbi_keep_final.txt

echo "Sequences to keep: $(wc -l < /tmp/ncbi_keep_final.txt)"

# Extract final sequences
samtools faidx $CLEAN \
    -r /tmp/ncbi_keep_final.txt \
    > $FINAL

# Reindex
samtools faidx $FINAL

echo ""
echo "=== Final FASTA stats ==="
echo "Sequences: $(grep -c '>' $FINAL)"
awk '{sum+=$2} END{printf "Total size: %.3f Gb\n", sum/1e9}' $FINAL.fai
awk '$2<200{print "WARNING: short sequence still present:", $1, $2}' \
    $FINAL.fai

# ============================================================
# STEP 4: Clean GFF3 to match final FASTA
# Remove any features on excluded sequences
# ============================================================
echo ""
echo "=== STEP 4: Cleaning GFF3 ==="

# Get list of sequence IDs in final FASTA
grep ">" $FINAL | sed 's/>//' > /tmp/ncbi_final_seqs.txt

# Keep GFF3 header lines and features only on kept sequences
awk 'NR==FNR{keep[$1]=1; next}
     /^#/{print; next}
     $1 in keep{print}' \
    /tmp/ncbi_final_seqs.txt \
    $GFF_CLEAN \
    > $GFF_FINAL

echo "Original GFF3 lines: $(grep -v '^#' $GFF_CLEAN | wc -l)"
echo "Final GFF3 lines:    $(grep -v '^#' $GFF_FINAL | wc -l)"
echo "Removed:             $(($(grep -v '^#' $GFF_CLEAN | wc -l) - \
                               $(grep -v '^#' $GFF_FINAL | wc -l))) lines"

# ============================================================
# STEP 5: Final validation
# ============================================================
echo ""
echo "=== STEP 5: Final validation ==="

# Check sequence IDs are NCBI compatible
echo "Checking sequence ID format..."
INVALID=$(grep ">" $FINAL | sed 's/>//' | \
    awk '{if(length($1)>50 || $1~/[^a-zA-Z0-9._-]/) print $1}' | wc -l)
echo "  Invalid IDs: $INVALID"

# Check no duplicate IDs
DUPS=$(grep ">" $FINAL | sed 's/>//' | sort | uniq -d | wc -l)
echo "  Duplicate IDs: $DUPS"

# Check GFF sequences all in FASTA
grep -v "^#" $GFF_FINAL | awk '{print $1}' | sort -u \
    > /tmp/val_gff_seqs.txt
grep ">" $FINAL | sed 's/>//' | sort \
    > /tmp/val_fasta_seqs.txt
GFF_MISSING=$(comm -23 /tmp/val_gff_seqs.txt /tmp/val_fasta_seqs.txt | wc -l)
echo "  GFF sequences missing from FASTA: $GFF_MISSING"

# Check minimum sequence length
MIN_LEN=$(awk 'BEGIN{m=999999} $2<m{m=$2} END{print m}' $FINAL.fai)
echo "  Minimum sequence length: $MIN_LEN bp"

# Final summary
echo ""
echo "=========================================="
echo "=== NCBI Submission Files Ready ==="
echo "=========================================="
echo "Assembly FASTA: $FINAL"
echo "Annotation GFF: $GFF_FINAL"
echo ""
echo "Assembly stats:"
echo "  Sequences: $(grep -c '>' $FINAL)"
awk '{sum+=$2; n++}
     END{printf "  Total size: %.3f Gb\n  Mean length: %.0f bp\n", 
         sum/1e9, sum/n}' $FINAL.fai
echo ""
if [ $INVALID -eq 0 ] && [ $DUPS -eq 0 ] && \
   [ $GFF_MISSING -eq 0 ] && [ $MIN_LEN -ge 200 ]; then
    echo "STATUS: PASS - assembly ready for NCBI submission"
else
    echo "STATUS: FAIL - review warnings above before submitting"
fi
echo "=========================================="
echo "[$(date)] g25_ncbi_prep complete"