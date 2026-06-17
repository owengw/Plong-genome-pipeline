#!/bin/bash
#SBATCH --job-name=g21_genespace
#SBATCH --output=g21_genespace_%j.log
#SBATCH --mem=256G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=48:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate /mnt/parscratch/users/bi4og/conda_envs/genespace_tools

# ============================================================
# ARGUMENTS
# Usage: sbatch g21_genespace.sh <plong_assembly>
# Example:
#   sbatch g21_genespace.sh fasciatus
#   sbatch g21_genespace.sh gilberti
# ============================================================

PLONG_ASSEMBLY=${1:?"ERROR: provide plong_assembly as argument 1 (fasciatus or gilberti)"}

src=/mnt/parscratch/users/bi4og
gs=$src/genespace_input_${PLONG_ASSEMBLY}
tools=$src/tools
of_env=/mnt/parscratch/users/bi4og/conda_envs/orthofinder

echo "=========================================="
echo "Running GENESPACE with P. longirostris: $PLONG_ASSEMBLY assembly"
echo "Input dir: $gs"
echo "=========================================="

echo "--- Verifying inputs ---"
echo "Peptide files:"; ls -lh $gs/peptide/
echo "BED files:";     ls -lh $gs/bed/
echo "MCScanX:";       ls $tools/MCScanX/MCScanX

echo "=========================================="
echo "STEP 1: Clean previous GENESPACE results (keep orthofinder)"
echo "=========================================="
rm -rf $gs/tmp $gs/results
rm -rf $gs/dotplots $gs/syntenicHits $gs/riparian $gs/pangenes
# Only clean orthofinder if it didn't complete successfully
if [ ! -f "$gs/orthofinder/Results_*/Orthogroups/Orthogroups.tsv" ]; then
    echo "No complete OrthoFinder results found - will rerun"
    rm -rf $gs/orthofinder
else
    echo "OrthoFinder results exist - keeping to avoid rerun"
fi
echo "Clean complete"

echo "=========================================="
echo "STEP 2: Init GENESPACE"
echo "=========================================="

cat > /tmp/genespace_init.R << 'EOF'
library(GENESPACE)
args    <- commandArgs(trailingOnly=TRUE)
gs      <- args[1]
tools   <- args[2]

gpar <- init_genespace(
    wd           = gs,
    path2mcscanx = file.path(tools, "MCScanX"),
    genomeIDs    = c("Plongirostris", "Pfasciatus", "Pgilberti",
                     "Tscincoides",   "Snitidus",   "Hcapensis"),
    speciesIDs   = c("Plongirostris", "Pfasciatus", "Pgilberti",
                     "Tscincoides",   "Snitidus",   "Hcapensis"),
    ploidy       = rep(1, 6),
    nCores       = 16
)
save(gpar, file = file.path(gs, "gpar_init.rda"))
cat("init complete\n")
EOF

Rscript /tmp/genespace_init.R $gs $tools

echo "=========================================="
echo "STEP 2b: Populate tmp directory"
echo "=========================================="
mkdir -p $gs/tmp
for sp in Plongirostris Pfasciatus Pgilberti Tscincoides Snitidus Hcapensis; do
    cp $gs/peptide/${sp}.fa $gs/tmp/${sp}.fa
    echo "Copied ${sp}.fa"
done

echo "=========================================="
echo "STEP 3: Clean stop codons"
echo "=========================================="
for f in $gs/tmp/*.fa; do
    sed -i '/^>/! s/\.//g' $f
    echo "Cleaned: $(basename $f)"
done

echo "=========================================="
echo "STEP 4: Run OrthoFinder"
echo "=========================================="
conda activate $of_env

orthofinder \
    -f $gs/tmp \
    -t 16 \
    -X \
    -o $gs/orthofinder

OF_EXIT=$?
echo "OrthoFinder exit code: $OF_EXIT"
if [ $OF_EXIT -ne 0 ]; then
    echo "ERROR: OrthoFinder failed"
    exit 1
fi

echo "=========================================="
echo "STEP 5: Run GENESPACE"
echo "=========================================="
conda activate /mnt/parscratch/users/bi4og/conda_envs/genespace_tools

cat > /tmp/genespace_run.R << 'EOF'
library(GENESPACE)
args <- commandArgs(trailingOnly=TRUE)
gs   <- args[1]

load(file.path(gs, "gpar_init.rda"))
cat("Running GENESPACE pipeline...\n")
gpar <- run_genespace(gsParam = gpar)
save(gpar, file = file.path(gs, "results/gsParams.rda"))
cat("GENESPACE complete\n")
EOF

Rscript /tmp/genespace_run.R $gs

echo "=========================================="
echo "g21 complete"
echo "Submit riparian with: sbatch g22_riparian_plot.sh $PLONG_ASSEMBLY"
echo "=========================================="