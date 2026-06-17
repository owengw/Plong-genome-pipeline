#!/bin/bash
#SBATCH --job-name=g20_genespace_prep
#SBATCH --output=g20_genespace_prep_%j.log
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=12:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate /mnt/parscratch/users/bi4og/conda_envs/genespace_tools

# ============================================================
# ARGUMENTS
# Usage: sbatch g20_genespace_prep.sh <plong_assembly>
# Where plong_assembly is either "fasciatus" or "gilberti"
# This controls which P. longirostris assembly/annotation is used
# Example:
#   sbatch g20_genespace_prep.sh fasciatus
#   sbatch g20_genespace_prep.sh gilberti
# ============================================================

PLONG_ASSEMBLY=${1:?"ERROR: provide plong_assembly as argument 1 (fasciatus or gilberti)"}

src=/mnt/parscratch/users/bi4og
gs=$src/genespace_input_${PLONG_ASSEMBLY}
tools=$src/tools

mkdir -p $gs/peptide $gs/bed $gs/downloads
mkdir -p $tools

which gffread && echo "gffread OK" || { echo "gffread not found"; exit 1; }

echo "=========================================="
echo "Using P. longirostris assembly: $PLONG_ASSEMBLY"
echo "GENESPACE input dir: $gs"
echo "=========================================="

# Set P. longirostris paths based on assembly choice
if [ "$PLONG_ASSEMBLY" == "gilberti" ]; then
    PLONG_GFF=$src/liftoff_polished_gilberti/Plongirostris_gilberti_polished.gff3
    PLONG_GENOME=$src/repeatmasker_gilberti/plongirostris_pilon_gilberti.fasta.masked
else
    PLONG_GFF=$src/liftoff_polished/Plestiodon_longirostris_polished.gff3
    PLONG_GENOME=$src/repeatmasker_polished/plongirostris_pilon.fasta.masked
fi

echo "P. longirostris GFF:    $PLONG_GFF"
echo "P. longirostris genome: $PLONG_GENOME"

# ============================================================
# STEP 1: NCBI datasets CLI
# ============================================================
echo "=========================================="
echo "STEP 1: NCBI datasets CLI"
echo "=========================================="
if [ ! -f $tools/datasets ]; then
    curl -o $tools/datasets \
        'https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/datasets'
    chmod +x $tools/datasets
fi
$tools/datasets --version && echo "datasets CLI OK"

# ============================================================
# STEP 2: MCScanX
# ============================================================
echo "=========================================="
echo "STEP 2: MCScanX"
echo "=========================================="
if [ ! -f $tools/MCScanX/MCScanX ]; then
    cd $tools
    git clone https://github.com/wyp1125/MCScanX.git
    cd MCScanX && make 2>&1
    cd $src
fi
ls $tools/MCScanX/MCScanX && echo "MCScanX OK"

# ============================================================
# STEP 3: Extract proteins via gffread
# ============================================================
echo "=========================================="
echo "STEP 3: Extract proteins via gffread"
echo "=========================================="

echo "--- P. longirostris (${PLONG_ASSEMBLY}-scaffolded) ---"
gffread \
    $PLONG_GFF \
    -g $PLONG_GENOME \
    -y $gs/peptide/Plongirostris.fa
sed -i '/^>/! s/\.//g' $gs/peptide/Plongirostris.fa
echo "Plongirostris proteins: $(grep -c '^>' $gs/peptide/Plongirostris.fa)"

echo "--- P. fasciatus ---"
gffread \
    $src/genome/Plestiodon_fasciatus.gff3 \
    -g $src/genome/rPleFas1.1.fasta \
    -y $gs/peptide/Pfasciatus.fa
sed -i '/^>/! s/\.//g' $gs/peptide/Pfasciatus.fa
echo "Pfasciatus proteins: $(grep -c '^>' $gs/peptide/Pfasciatus.fa)"

echo "--- P. gilberti ---"
gffread \
    $src/genome/Pgilberti.gff \
    -g $src/genome/Pgilberti.fna \
    -y $gs/peptide/Pgilberti.fa
sed -i '/^>/! s/\.//g' $gs/peptide/Pgilberti.fa
echo "Pgilberti proteins: $(grep -c '^>' $gs/peptide/Pgilberti.fa)"

echo "--- Tiliqua scincoides (GCF_035046505.1) ---"
if [ ! -f $gs/downloads/Tiliqua_genomic.gff ]; then
    $tools/datasets download genome accession GCF_035046505.1 \
        --include genome,gff3,protein \
        --filename $gs/downloads/Tiliqua.zip
    unzip -o $gs/downloads/Tiliqua.zip -d $gs/downloads/Tiliqua
fi
cp $gs/downloads/Tiliqua/ncbi_dataset/data/GCF_035046505.1/protein.faa \
    $gs/peptide/Tscincoides.fa
cp $gs/downloads/Tiliqua/ncbi_dataset/data/GCF_035046505.1/genomic.gff \
    $gs/downloads/Tiliqua_genomic.gff
cp $gs/downloads/Tiliqua/ncbi_dataset/data/GCF_035046505.1/*_genomic.fna \
    $gs/downloads/Tiliqua_genome.fna
sed -i 's/>\([^ ]*\).*/>\1/' $gs/peptide/Tscincoides.fa
sed -i '/^>/! s/\.//g' $gs/peptide/Tscincoides.fa
echo "Tscincoides proteins: $(grep -c '^>' $gs/peptide/Tscincoides.fa)"

echo "--- Spondylurus nitidus ---"
if [ ! -f $gs/downloads/Spondylurus_genome.fna ]; then
    $tools/datasets download genome taxon "Spondylurus nitidus" \
        --assembly-level chromosome \
        --include genome \
        --filename $gs/downloads/Spondylurus.zip
    unzip -o $gs/downloads/Spondylurus.zip -d $gs/downloads/Spondylurus
    SPON_ACC=$(ls $gs/downloads/Spondylurus/ncbi_dataset/data/ \
        | grep -v assembly | grep -v dataset | head -1)
    cp $gs/downloads/Spondylurus/ncbi_dataset/data/$SPON_ACC/*_genomic.fna \
        $gs/downloads/Spondylurus_genome.fna
fi
if [ ! -f $gs/downloads/Spondylurus_genomic.gff ]; then
    conda activate /mnt/parscratch/users/bi4og/users/bi4og/conda_envs/liftoff
    mkdir -p $gs/downloads/Spondylurus_liftoff_intermediate
    liftoff \
        $gs/downloads/Spondylurus_genome.fna \
        $src/genome/rPleFas1.1.fasta \
        -g $src/genome/Plestiodon_fasciatus.gff3 \
        -o $gs/downloads/Spondylurus_genomic.gff \
        -u $gs/downloads/Spondylurus_unmapped.txt \
        -p 16 \
        -dir $gs/downloads/Spondylurus_liftoff_intermediate
    conda activate /mnt/parscratch/users/bi4og/conda_envs/genespace_tools
fi
gffread \
    $gs/downloads/Spondylurus_genomic.gff \
    -g $gs/downloads/Spondylurus_genome.fna \
    -y $gs/peptide/Snitidus.fa
sed -i '/^>/! s/\.//g' $gs/peptide/Snitidus.fa
echo "Snitidus proteins: $(grep -c '^>' $gs/peptide/Snitidus.fa)"

echo "--- Hemicordylus capensis (GCF_027244095.1) ---"
FASC_HCAP=$src/genespace_input_fasciatus/peptide/Hcapensis.fa

if [ -f $gs/peptide/Hcapensis.fa ] && [ -f $gs/bed/Hcapensis.bed ]; then
    echo "Hcapensis already exists in $gs — skipping"
elif [ -f $FASC_HCAP ]; then
    echo "Copying Hcapensis from fasciatus run..."
    cp $src/genespace_input_fasciatus/peptide/Hcapensis.fa $gs/peptide/Hcapensis.fa
    cp $src/genespace_input_fasciatus/bed/Hcapensis.bed    $gs/bed/Hcapensis.bed
    # Also copy downloads so liftoff intermediate isn't needed
    mkdir -p $gs/downloads
    cp $src/genespace_input_fasciatus/downloads/Hemicordylus_genomic.gff \
       $gs/downloads/Hemicordylus_genomic.gff 2>/dev/null || true
else
    echo "Downloading Hemicordylus from NCBI..."
    if [ ! -f $gs/downloads/Hemicordylus_genomic.gff ]; then
        $tools/datasets download genome accession GCF_027244095.1 \
            --include genome,gff3,protein \
            --filename $gs/downloads/Hemicordylus.zip
        unzip -o $gs/downloads/Hemicordylus.zip -d $gs/downloads/Hemicordylus
    fi
    cp $gs/downloads/Hemicordylus/ncbi_dataset/data/GCF_027244095.1/protein.faa \
        $gs/peptide/Hcapensis.fa
    cp $gs/downloads/Hemicordylus/ncbi_dataset/data/GCF_027244095.1/genomic.gff \
        $gs/downloads/Hemicordylus_genomic.gff
    sed -i 's/>\([^ ]*\).*/>\1/' $gs/peptide/Hcapensis.fa
    sed -i '/^>/! s/\.//g' $gs/peptide/Hcapensis.fa
    bed_from_ncbi_refseq \
        $gs/downloads/Hemicordylus_genomic.gff \
        $gs/bed/Hcapensis.bed "Hcapensis"
fi
echo "Hcapensis proteins: $(grep -c '^>' $gs/peptide/Hcapensis.fa)"

# ============================================================
# STEP 4: Generate BED files
# ============================================================
echo "=========================================="
echo "STEP 4: Generate BED files"
echo "=========================================="

bed_from_mrna_id() {
    local GFF=$1
    local BED=$2
    local LABEL=$3
    echo "--- $LABEL ---"
    grep -P "\tmRNA\t|\ttranscript\t" $GFF | \
        awk 'BEGIN{OFS="\t"} {
            match($9, /ID=([^;]+)/, arr)
            id = arr[1]
            if (id == "") next
            print $1, $4-1, $5, id
        }' | \
        sort -k4,4 -k3,3rn | \
        python3 -c "
import sys
seen = set()
for line in sys.stdin:
    f = line.strip().split('\t')
    if f[3] not in seen:
        seen.add(f[3])
        print(line, end='')
" > $BED
    echo "  $(wc -l < $BED) entries"
}

bed_from_ncbi_refseq() {
    local GFF=$1
    local BED=$2
    local LABEL=$3
    echo "--- $LABEL ---"
    python3 << PYEOF
import sys
gff_path = "$GFF"
out_path  = "$BED"
mrna = {}
with open(gff_path) as f:
    for line in f:
        if line.startswith('#'): continue
        fields = line.strip().split('\t')
        if len(fields) < 9: continue
        if fields[2] != 'mRNA': continue
        attrs = dict(a.split('=',1) for a in fields[8].split(';') if '=' in a)
        mid = attrs.get('ID','')
        if not mid: continue
        mrna[mid] = (fields[0], int(fields[3])-1, int(fields[4]), fields[6])
cds_protein = {}
cds_len = {}
with open(gff_path) as f:
    for line in f:
        if line.startswith('#'): continue
        fields = line.strip().split('\t')
        if len(fields) < 9: continue
        if fields[2] != 'CDS': continue
        attrs = dict(a.split('=',1) for a in fields[8].split(';') if '=' in a)
        pid    = attrs.get('protein_id','')
        parent = attrs.get('Parent','')
        if not pid or not parent: continue
        length = int(fields[4]) - int(fields[3])
        if parent not in cds_len or length > cds_len[parent]:
            cds_len[parent] = length
            cds_protein[parent] = pid
seen = set()
count = 0
with open(out_path, 'w') as out:
    for mid, (chrom, start, end, strand) in mrna.items():
        pid = cds_protein.get(mid,'')
        if not pid or pid in seen: continue
        seen.add(pid)
        out.write(f"{chrom}\t{start}\t{end}\t{pid}\n")
        count += 1
print(f"  {count} entries written")
PYEOF
}

bed_from_mrna_id $PLONG_GFF $gs/bed/Plongirostris.bed "Plongirostris"
bed_from_mrna_id $src/genome/Plestiodon_fasciatus.gff3 $gs/bed/Pfasciatus.bed "Pfasciatus"
bed_from_mrna_id $src/genome/Pgilberti.gff $gs/bed/Pgilberti.bed "Pgilberti"
bed_from_ncbi_refseq $gs/downloads/Tiliqua_genomic.gff $gs/bed/Tscincoides.bed "Tscincoides"
bed_from_mrna_id $gs/downloads/Spondylurus_genomic.gff $gs/bed/Snitidus.bed "Snitidus"
bed_from_ncbi_refseq $gs/downloads/Hemicordylus_genomic.gff $gs/bed/Hcapensis.bed "Hcapensis"

# ============================================================
# STEP 5: Validate
# ============================================================
echo "=========================================="
echo "STEP 5: Validate BED vs FASTA ID matching"
echo "=========================================="
for sp in Plongirostris Pfasciatus Pgilberti Tscincoides Snitidus Hcapensis; do
    grep '^>' $gs/peptide/${sp}.fa | sed 's/>//' | \
        awk '{print $1}' | sort > /tmp/fasta_ids.txt
    awk '{print $4}' $gs/bed/${sp}.bed | sort > /tmp/bed_ids.txt
    FASTA=$(wc -l < /tmp/fasta_ids.txt)
    BED=$(wc -l < /tmp/bed_ids.txt)
    MATCH=$(comm -12 /tmp/fasta_ids.txt /tmp/bed_ids.txt | wc -l)
    STATUS=$([ "$MATCH" -gt 0 ] && echo "OK" || echo "FAIL - check IDs")
    echo "$sp: FASTA=$FASTA BED=$BED MATCHING=$MATCH [$STATUS]"
done

echo "=========================================="
echo "STEP 6: Verify BED column count"
echo "=========================================="
for sp in Plongirostris Pfasciatus Pgilberti Tscincoides Snitidus Hcapensis; do
    COLS=$(awk '{print NF; exit}' $gs/bed/${sp}.bed)
    echo "$sp: $COLS columns $([ "$COLS" -eq 4 ] && echo 'OK' || echo 'FAIL')"
done

echo "=========================================="
echo "STEP 7: Final file check"
echo "=========================================="
echo "Peptide files:"; ls -lh $gs/peptide/
echo "BED files:";     ls -lh $gs/bed/
echo "MCScanX:";       ls $tools/MCScanX/MCScanX && echo "OK"
echo "=========================================="
echo "g20 complete - ready to submit g21 with: sbatch g21_genespace.sh $PLONG_ASSEMBLY"
echo "=========================================="