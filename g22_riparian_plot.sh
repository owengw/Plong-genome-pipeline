#!/bin/bash
#SBATCH --job-name=g22_riparian_plot
#SBATCH --output=g22_riparian_plot_%j.log
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --time=01:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate /mnt/parscratch/users/bi4og/conda_envs/genespace_tools

# ============================================================
# ARGUMENTS
# Usage: sbatch g22_riparian_plot.sh <plong_assembly>
# Example:
#   sbatch g22_riparian_plot.sh fasciatus
#   sbatch g22_riparian_plot.sh gilberti
# ============================================================

PLONG_ASSEMBLY=${1:?"ERROR: provide plong_assembly as argument 1 (fasciatus or gilberti)"}

src=/mnt/parscratch/users/bi4og
gs=$src/genespace_input_${PLONG_ASSEMBLY}

cat > /tmp/g22_riparian.R << EOF
library(GENESPACE)
gs <- "$gs"
load(file.path(gs, "results/gsParams.rda"))

png(file.path(gs, "synteny_riparian_ordered.png"),
    width=16, height=10, units="in", res=300)
plot_riparian(
    gsParam          = gpar,
    genomeIDs        = c("Plongirostris", "Pgilberti", "Pfasciatus",
                         "Snitidus",   "Tscincoides",   "Hcapensis"),
    refGenome        = "Plongirostris",
    useRegions       = TRUE,
    backgroundColor  = "white",
    braidAlpha       = 0.75,
    chrFill          = "grey85",
    chrBorderCol     = "grey50",
    chrBorderLwd     = 0.3,
    chrLabFontSize   = 3.5,
    reorderBySynteny = FALSE
)
dev.off()
cat("Done\n")
EOF

Rscript /tmp/g22_riparian.R

echo "--- g22 complete ---"
echo "Download: $gs/synteny_riparian_ordered.png"