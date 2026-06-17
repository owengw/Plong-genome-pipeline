#!/bin/bash
#SBATCH --job-name=g19b_sex_chr_synteny
#SBATCH --output=g19b_sex_chr_synteny_%j.log
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=06:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate base

src=/mnt/parscratch/users/bi4og
OUTDIR=$src/synteny/sex_chromosome
mkdir -p $OUTDIR

# ============================================================
# STEP 1: Download Acritoscincus duperreyi genome
# GCA_041722995.2 - chromosome-level assembly with known X chromosome
# Used in Richmond et al. 2026 P. gilberti paper to identify sex chromosomes
# ============================================================

echo "--- Downloading Acritoscincus duperreyi genome ---"
if [ ! -f $src/genome/Aduperreyi.fna ]; then
    $src/tools/datasets download genome accession GCA_041722995.2 \
        --include genome \
        --filename $src/genome/Aduperreyi.zip

    unzip -o $src/genome/Aduperreyi.zip \
        -d $src/genome/Aduperreyi_tmp

    cp $src/genome/Aduperreyi_tmp/ncbi_dataset/data/GCA_041722995.2/*_genomic.fna \
        $src/genome/Aduperreyi.fna

    rm -rf $src/genome/Aduperreyi_tmp $src/genome/Aduperreyi.zip
    echo "Download complete: $src/genome/Aduperreyi.fna"
else
    echo "Already exists: $src/genome/Aduperreyi.fna"
fi

# Index for D-GENIES
conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen
samtools faidx $src/genome/Aduperreyi.fna
conda activate base
awk '$2>1000000 {print $1"\t"$2}' \
    $src/genome/Aduperreyi.fna.fai \
    > $OUTDIR/Aduperreyi_chronly.idx
echo "A. duperreyi chromosomes:"
cat $OUTDIR/Aduperreyi_chronly.idx

# ============================================================
# STEP 2: Align P. longirostris vs A. duperreyi
# Using asm20 preset - appropriate for ~150 Ma divergence
# asm5  = <5% divergence (same species/genus)
# asm20 = <20% divergence (family/order level)
# ============================================================

echo "--- Running minimap2: P. longirostris (fasciatus scaffold) vs A. duperreyi ---"
minimap2 -cx asm20 \
    --cs \
    -t 16 \
    $src/genome/Aduperreyi.fna \
    $src/repeatmasker_polished/plongirostris_pilon.fasta.masked \
    > $OUTDIR/Plong_fasciatus_vs_Aduperreyi.paf

echo "--- Filtering to chromosome-level alignments ---"
awk '$1~/^chr/ && $10>1000' \
    $OUTDIR/Plong_fasciatus_vs_Aduperreyi.paf \
    > $OUTDIR/Plong_fasciatus_vs_Aduperreyi_chronly.paf

echo "--- Generating P. longirostris idx for D-GENIES ---"
grep "^chr" $src/repeatmasker_polished/plongirostris_pilon.fasta.masked.fai | \
    awk '{print $1"\t"$2}' \
    > $OUTDIR/Plongirostris_fasciatus_chronly.idx

echo "============================================"
echo "PAF stats:"
echo "Total alignments: $(wc -l < $OUTDIR/Plong_fasciatus_vs_Aduperreyi.paf)"
echo "Chr-level alignments: $(wc -l < $OUTDIR/Plong_fasciatus_vs_Aduperreyi_chronly.paf)"
echo ""
echo "Upload to D-GENIES: https://dgenies.toulouse.inrae.fr/run"
echo "  Alignment: $OUTDIR/Plong_fasciatus_vs_Aduperreyi_chronly.paf"
echo "  Target:    $OUTDIR/Aduperreyi_chronly.idx"
echo "  Query:     $OUTDIR/Plongirostris_fasciatus_chronly.idx"
echo ""
echo "The A. duperreyi X chromosome is chromosome 8 (NC_088024.1)"
echo "Whichever P. longirostris chromosome aligns to it is the putative X"
echo "============================================"