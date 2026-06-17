#!/bin/bash
#SBATCH --job-name=g23_genome_density
#SBATCH --output=g23_genome_density_%j.log
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=04:00:00

source ~/.bash_profile
source /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
conda activate /mnt/parscratch/users/bi4og/conda_envs/genespace_tools

# ============================================================
# ARGUMENTS
# Usage: sbatch g23_genome_density.sh <masked_fasta> <gff3> <output_prefix>
# Example (fasciatus):
#   sbatch g23_genome_density.sh \
#     /mnt/parscratch/users/bi4og/repeatmasker_polished/plongirostris_pilon.fasta.masked \
#     /mnt/parscratch/users/bi4og/liftoff_polished/Plestiodon_longirostris_polished.gff3 \
#     fasciatus
# Example (gilberti):
#   sbatch g23_genome_density.sh \
#     /mnt/parscratch/users/bi4og/repeatmasker_gilberti/plongirostris_pilon_gilberti.fasta.masked \
#     /mnt/parscratch/users/bi4og/liftoff_polished_gilberti/Plongirostris_gilberti_polished.gff3 \
#     gilberti
# ============================================================

MASKED_FA=${1:?"ERROR: provide masked fasta as argument 1"}
GFF3=${2:?"ERROR: provide GFF3 as argument 2"}
PREFIX=${3:?"ERROR: provide output prefix as argument 3"}

echo "Input assembly: $MASKED_FA"
echo "Input GFF3:     $GFF3"
echo "Output prefix:  $PREFIX"

[ ! -f "$MASKED_FA" ] && echo "ERROR: $MASKED_FA not found" && exit 1
[ ! -f "$GFF3" ]      && echo "ERROR: $GFF3 not found"      && exit 1

FAI="${MASKED_FA}.fai"
if [ ! -f "$FAI" ]; then
    echo "Generating FAI index..."
    conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen
    samtools faidx $MASKED_FA
    conda activate /mnt/parscratch/users/bi4og/conda_envs/genespace_tools
fi

OUTDIR=$(dirname $MASKED_FA)

# ============================================================
# Write R script - split heredoc to handle bash variables
# Part 1: unquoted REOF allows bash variable substitution for paths
# Part 2: quoted 'REOF' passes R code literally (no $ interpretation)
# ============================================================

cat > /tmp/g23_density_${PREFIX}.R << REOF
library(data.table)
library(ggplot2)

masked_fa  <- "${MASKED_FA}"
fai_file   <- "${FAI}"
gff_file   <- "${GFF3}"
prefix     <- "${PREFIX}"
out_dir    <- "${OUTDIR}"
REOF

cat >> /tmp/g23_density_${PREFIX}.R << 'REOF'

# ============================================================
# 1. CHROMOSOME SIZES FROM FAI
# ============================================================

fai <- fread(fai_file, header=FALSE,
             col.names=c("chr","length","offset","bases","bytes"))

chrs <- fai[grepl("^chr.*RagTag|^JANXHV.*RagTag", chr)]
chrs[, chr_label := gsub("_RagTag_pilon|_RagTag", "", chr)]
chrs[, chr_label := gsub("JANXHV010000+0*(\\d+)\\.1", "chr\\1",
                         chr_label, perl=TRUE)]
chrs[, chr_num   := as.integer(gsub("chr", "", chr_label))]
chrs <- chrs[order(chr_num)]

cat("Chromosomes found:", nrow(chrs), "\n")
print(chrs[, .(chr, chr_label, length)])

# ============================================================
# 2. SLIDING WINDOWS
# ============================================================

window_size <- 1000000L
step_size   <- 500000L

windows <- rbindlist(lapply(1:nrow(chrs), function(i) {
    starts <- seq(1L, chrs$length[i], by=step_size)
    ends   <- pmin(starts + window_size - 1L, chrs$length[i])
    data.table(
        chr       = chrs$chr[i],
        chr_label = chrs$chr_label[i],
        chr_num   = chrs$chr_num[i],
        start     = starts,
        end       = ends,
        mid       = (starts + ends) / 2
    )
}))

cat("Total windows:", nrow(windows), "\n")

# ============================================================
# 3. GENE DENSITY
# ============================================================

cat("Loading GFF3...\n")
gff <- fread(cmd=paste0("grep -v '^#' ", gff_file),
             header=FALSE, sep="\t",
             col.names=c("chr","source","feature","start","end",
                         "score","strand","frame","attr"),
             showProgress=FALSE, fill=TRUE)

genes <- gff[feature == "gene" & chr %in% chrs$chr]
cat("Genes on named chromosomes:", nrow(genes), "\n")

cat("Calculating gene density...\n")
windows[, gene_count := 0L]
for(i in seq_len(nrow(windows))) {
    windows$gene_count[i] <- genes[
        chr == windows$chr[i] &
        start <= windows$end[i] &
        end >= windows$start[i], .N]
    if(i %% 500 == 0) cat("  Window", i, "of", nrow(windows), "\n")
}
windows[, gene_density := gene_count / (window_size / 1e6)]
cat("Gene density done\n")

# ============================================================
# 4. REPEAT DENSITY
# ============================================================

out_file <- sub("\\.masked$", ".out", masked_fa)
cat("Loading RepeatMasker output:", out_file, "\n")

rm_out <- fread(cmd=paste0("grep -v '^#' ", out_file),
                skip=2, header=FALSE, fill=TRUE,
                col.names=c("sw_score","div","del","ins",
                            "query","qstart","qend","qleft",
                            "strand","repeat_name","class_family",
                            "rstart","rend","rleft","ID","extra"),
                showProgress=FALSE)

rm_out <- rm_out[, 1:15]
rm_out <- rm_out[query %in% chrs$chr]
rm_out[, qstart := as.integer(qstart)]
rm_out[, qend   := as.integer(qend)]

cat("Repeat annotations on named chromosomes:", nrow(rm_out), "\n")

cat("Calculating repeat density...\n")
windows[, repeat_bp := 0L]
for(i in seq_len(nrow(windows))) {
    overlaps <- rm_out[
        query == windows$chr[i] &
        qstart <= windows$end[i] &
        qend >= windows$start[i]]
    if(nrow(overlaps) > 0) {
        clipped_start <- pmax(overlaps$qstart, windows$start[i])
        clipped_end   <- pmin(overlaps$qend,   windows$end[i])
        windows$repeat_bp[i] <- sum(clipped_end - clipped_start + 1L)
    }
    if(i %% 500 == 0) cat("  Window", i, "of", nrow(windows), "\n")
}
windows[, repeat_pct := (repeat_bp / window_size) * 100]
cat("Repeat density done\n")

# ============================================================
# 5. SAVE AND PLOT
# ============================================================

fwrite(windows, file.path(out_dir, paste0(prefix, "_genomic_windows.csv")))

windows[, chr_label := factor(chr_label, levels=paste0("chr", 1:13))]

# Gene density
p1 <- ggplot(windows, aes(x=mid/1e6, y=gene_density)) +
    geom_area(fill="#2166ac", alpha=0.7, colour="#2166ac", linewidth=0.2) +
    facet_wrap(~chr_label, nrow=2, scales="free_x") +
    scale_x_continuous(labels=function(x) paste0(x,"M")) +
    scale_y_continuous(expand=expansion(mult=c(0, 0.1))) +
    labs(title=paste0("Gene density — Plestiodon longirostris (", prefix, " assembly)"),
         x="Position (Mb)", y="Genes per Mb") +
    theme_bw(base_size=10) +
    theme(
        plot.title       = element_text(hjust=0, face="bold"),
        strip.background = element_rect(fill="#2166ac"),
        strip.text       = element_text(colour="white", face="bold"),
        panel.grid.minor = element_blank(),
        axis.text.x      = element_text(size=7)
    )

ggsave(file.path(out_dir, paste0(prefix, "_gene_density.pdf")),
       plot=p1, width=16, height=8, units="in")
ggsave(file.path(out_dir, paste0(prefix, "_gene_density.png")),
       plot=p1, width=16, height=8, units="in", dpi=300)
cat("Gene density plot saved\n")

# Repeat density
p2 <- ggplot(windows, aes(x=mid/1e6, y=repeat_pct)) +
    geom_area(fill="#d73027", alpha=0.7, colour="#d73027", linewidth=0.2) +
    facet_wrap(~chr_label, nrow=2, scales="free_x") +
    scale_x_continuous(labels=function(x) paste0(x,"M")) +
    scale_y_continuous(expand=expansion(mult=c(0, 0.1)), limits=c(0, 100)) +
    labs(title=paste0("Repeat density — Plestiodon longirostris (", prefix, " assembly)"),
         x="Position (Mb)", y="Repeat content (%)") +
    theme_bw(base_size=10) +
    theme(
        plot.title       = element_text(hjust=0, face="bold"),
        strip.background = element_rect(fill="#d73027"),
        strip.text       = element_text(colour="white", face="bold"),
        panel.grid.minor = element_blank(),
        axis.text.x      = element_text(size=7)
    )

ggsave(file.path(out_dir, paste0(prefix, "_repeat_density.pdf")),
       plot=p2, width=16, height=8, units="in")
ggsave(file.path(out_dir, paste0(prefix, "_repeat_density.png")),
       plot=p2, width=16, height=8, units="in", dpi=300)
cat("Repeat density plot saved\n")

# Combined landscape
windows_long <- rbind(
    data.table(chr_label=windows$chr_label, mid=windows$mid,
               value=windows$gene_density, metric="Gene density (genes/Mb)"),
    data.table(chr_label=windows$chr_label, mid=windows$mid,
               value=windows$repeat_pct,   metric="Repeat content (%)")
)
windows_long[, chr_label := factor(chr_label, levels=paste0("chr", 1:13))]
windows_long[, metric := factor(metric,
    levels=c("Gene density (genes/Mb)", "Repeat content (%)"))]

p3 <- ggplot(windows_long, aes(x=mid/1e6, y=value, fill=metric, colour=metric)) +
    geom_area(alpha=0.6, linewidth=0.2) +
    facet_grid(metric ~ chr_label, scales="free") +
    scale_fill_manual(values=c("Gene density (genes/Mb)"="#2166ac",
                               "Repeat content (%)"="#d73027"), guide="none") +
    scale_colour_manual(values=c("Gene density (genes/Mb)"="#2166ac",
                                 "Repeat content (%)"="#d73027"), guide="none") +
    scale_x_continuous(labels=function(x) paste0(x,"M")) +
    labs(title=paste0("Genomic landscape — Plestiodon longirostris (",
                      prefix, " assembly)"),
         x="Chromosomal position (Mb)", y=NULL) +
    theme_bw(base_size=9) +
    theme(
        plot.title       = element_text(hjust=0, face="bold", size=12),
        strip.background = element_rect(fill="grey20"),
        strip.text       = element_text(colour="white", face="bold", size=7),
        strip.text.y     = element_text(angle=0, size=8),
        panel.grid.minor = element_blank(),
        axis.text.x      = element_text(size=6, angle=45, hjust=1)
    )

ggsave(file.path(out_dir, paste0(prefix, "_genomic_landscape.pdf")),
       plot=p3, width=22, height=6, units="in")
ggsave(file.path(out_dir, paste0(prefix, "_genomic_landscape.png")),
       plot=p3, width=22, height=6, units="in", dpi=300)
cat("Combined landscape plot saved\n")

cat("\n--- All done ---\n")
cat("Outputs in:", out_dir, "\n")
REOF

Rscript /tmp/g23_density_${PREFIX}.R

echo "--- g23 complete ---"
echo "Outputs in: $OUTDIR"