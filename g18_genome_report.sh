#!/bin/bash
#SBATCH --job-name=g18_genome_report
#SBATCH --output=g18_genome_report.log
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --time=2:00:00

source ~/.bash_profile

src=/mnt/parscratch/users/bi4og
report=$src/genome_report/plongirostris_genome_report.html
BUSCO_DIR=$src/mnt/parscratch/users/bi4og/busco_polished

mkdir -p $src/genome_report

# --- Collect software versions ---
conda activate /mnt/parscratch/users/bi4og/conda_envs/owenspopgen
FLYE_VER=$(flye --version 2>&1 | head -1)
MEDAKA_VER=$(medaka --version 2>&1 | head -1)
BUSCO_VER=$(busco --version 2>&1 | head -1)
QUAST_VER=$(quast --version 2>&1 | head -1)
conda deactivate

conda activate /mnt/parscratch/users/bi4og/users/bi4og/conda_envs/ragtag
RAGTAG_VER=$(ragtag.py --version 2>&1 | head -1)
MINIMAP2_VER=$(minimap2 --version 2>&1 | head -1)
conda deactivate

conda activate /mnt/parscratch/users/bi4og/users/bi4og/conda_envs/liftoff
LIFTOFF_VER=$(liftoff --version 2>&1 | head -1)
conda deactivate

conda activate /mnt/parscratch/users/bi4og/conda_envs/repeatmasker
REPEATMODELER_VER=$(RepeatModeler --version 2>&1 | head -1)
REPEATMASKER_VER=$(RepeatMasker --version 2>&1 | head -1)
conda deactivate

conda activate /mnt/parscratch/users/bi4og/conda_envs/pilon
PILON_VER=$(java -jar /mnt/parscratch/users/bi4og/conda_envs/pilon/share/pilon-1.24-0/pilon.jar --version 2>&1 | head -1)
conda deactivate

# --- Collect BUSCO results (v6 txt format) ---
BUSCO_TXT=$BUSCO_DIR/short_summary.specific.squamata_odb12.busco_polished.txt
BUSCO_COMPLETE=$(grep "Complete BUSCOs" $BUSCO_TXT | awk '{print $1}')
BUSCO_STOP=$(grep "internal stop codons" $BUSCO_TXT | grep -oP '\(of which \K[0-9]+')
BUSCO_SINGLE=$(grep "Complete and single-copy" $BUSCO_TXT | awk '{print $1}')
BUSCO_DUP=$(grep "Complete and duplicated" $BUSCO_TXT | awk '{print $1}')
BUSCO_FRAG=$(grep "Fragmented BUSCOs" $BUSCO_TXT | awk '{print $1}')
BUSCO_MISSING=$(grep "Missing BUSCOs" $BUSCO_TXT | awk '{print $1}')
BUSCO_TOTAL=$(grep "Total BUSCO groups" $BUSCO_TXT | awk '{print $1}')
BUSCO_C_PCT=$(awk "BEGIN {printf \"%.1f\", $BUSCO_COMPLETE/$BUSCO_TOTAL*100}")
BUSCO_S_PCT=$(awk "BEGIN {printf \"%.1f\", $BUSCO_SINGLE/$BUSCO_TOTAL*100}")
BUSCO_D_PCT=$(awk "BEGIN {printf \"%.1f\", $BUSCO_DUP/$BUSCO_TOTAL*100}")
BUSCO_F_PCT=$(awk "BEGIN {printf \"%.1f\", $BUSCO_FRAG/$BUSCO_TOTAL*100}")
BUSCO_M_PCT=$(awk "BEGIN {printf \"%.1f\", $BUSCO_MISSING/$BUSCO_TOTAL*100}")
BUSCO_STOP_PCT=$(awk "BEGIN {printf \"%.1f\", $BUSCO_STOP/$BUSCO_COMPLETE*100}")

# --- Collect QUAST results from TSV ---
QUAST_TSV=$src/quast_polished/report.tsv
get_quast() { grep -P "^$1\t" $QUAST_TSV | awk -F'\t' "{print \$$2}"; }
Q_LEN_FLY=$(get_quast "Total length" 2)
Q_LEN_RAG=$(get_quast "Total length" 3)
Q_LEN_POL=$(get_quast "Total length" 4)
Q_N50_FLY=$(get_quast "N50" 2)
Q_N50_RAG=$(get_quast "N50" 3)
Q_N50_POL=$(get_quast "N50" 4)
Q_L50_FLY=$(get_quast "L50" 2)
Q_L50_RAG=$(get_quast "L50" 3)
Q_L50_POL=$(get_quast "L50" 4)
Q_AUN_FLY=$(get_quast "auN" 2)
Q_AUN_RAG=$(get_quast "auN" 3)
Q_AUN_POL=$(get_quast "auN" 4)
Q_NS_FLY=$(get_quast "# N's per 100 kbp" 2)
Q_NS_RAG=$(get_quast "# N's per 100 kbp" 3)
Q_NS_POL=$(get_quast "# N's per 100 kbp" 4)
Q_LARGE_FLY=$(get_quast "Largest contig" 2)
Q_LARGE_RAG=$(get_quast "Largest contig" 3)
Q_LARGE_POL=$(get_quast "Largest contig" 4)
Q_MIS_FLY=$(get_quast "# misassemblies" 2)
Q_MIS_RAG=$(get_quast "# misassemblies" 3)
Q_MIS_POL=$(get_quast "# misassemblies" 4)
Q_NA50_FLY=$(get_quast "NA50" 2)
Q_NA50_RAG=$(get_quast "NA50" 3)
Q_NA50_POL=$(get_quast "NA50" 4)
Q_INDEL_FLY=$(get_quast "# indels per 100 kbp" 2)
Q_INDEL_RAG=$(get_quast "# indels per 100 kbp" 3)
Q_INDEL_POL=$(get_quast "# indels per 100 kbp" 4)
Q_GC_FLY=$(grep "^GC (%)" $QUAST_TSV | awk -F'\t' '{print $2}')
Q_GC_RAG=$(grep "^GC (%)" $QUAST_TSV | awk -F'\t' '{print $3}')
Q_GC_POL=$(grep "^GC (%)" $QUAST_TSV | awk -F'\t' '{print $4}')
Q_GF_FLY=$(grep "^Genome fraction (%)" $QUAST_TSV | awk -F'\t' '{print $2}')
Q_GF_RAG=$(grep "^Genome fraction (%)" $QUAST_TSV | awk -F'\t' '{print $3}')
Q_GF_POL=$(grep "^Genome fraction (%)" $QUAST_TSV | awk -F'\t' '{print $4}')

# --- Collect Liftoff results ---
LIFTOFF_REF_GENES=$(grep -P "\tgene\t" $src/genome/Plestiodon_fasciatus.gff3 | wc -l)
LIFTOFF_SCAFFOLD_GENES=$(grep -P "\tgene\t" $src/genome/liftoff_output/Plestiodon_longirostris.gff3 2>/dev/null | wc -l)
LIFTOFF_SCAFFOLD_UNMAPPED=$(wc -l < $src/genome/liftoff_output/unmapped_features.txt 2>/dev/null)
LIFTOFF_SCAFFOLD_PCT=$(awk "BEGIN {printf \"%.1f\", $LIFTOFF_SCAFFOLD_GENES/$LIFTOFF_REF_GENES*100}")
LIFTOFF_POLISHED_GENES=$(grep -P "\tgene\t" $src/liftoff_polished/Plestiodon_longirostris_polished.gff3 2>/dev/null | wc -l)
LIFTOFF_POLISHED_UNMAPPED=$(wc -l < $src/liftoff_polished/unmapped_features.txt 2>/dev/null)
LIFTOFF_POLISHED_PCT=$(awk "BEGIN {printf \"%.1f\", $LIFTOFF_POLISHED_GENES/$LIFTOFF_REF_GENES*100}")

# --- Collect RepeatMasker stats from tbl ---
RM_TBL=$src/repeatmasker_polished/plongirostris_pilon.fasta.tbl
RM_TOTAL_BP=$(grep "bases masked" $RM_TBL | awk '{print $3}')
RM_TOTAL_PCT=$(grep "bases masked" $RM_TBL | awk '{print $6}')
RM_RETROELEMENTS=$(grep "Retroelements" $RM_TBL | awk '{print $3}')
RM_RETRO_PCT=$(grep "Retroelements" $RM_TBL | awk '{print $5}')
RM_SINES=$(grep "SINEs:" $RM_TBL | awk '{print $3}')
RM_SINES_PCT=$(grep "SINEs:" $RM_TBL | awk '{print $5}')
RM_LINES=$(grep "LINEs:" $RM_TBL | awk '{print $3}')
RM_LINES_PCT=$(grep "LINEs:" $RM_TBL | awk '{print $5}')
RM_LTR=$(grep "LTR elements:" $RM_TBL | awk '{print $4}')
RM_LTR_PCT=$(grep "LTR elements:" $RM_TBL | awk '{print $6}')
RM_DNA=$(grep "DNA transposons" $RM_TBL | awk '{print $3}')
RM_DNA_PCT=$(grep "DNA transposons" $RM_TBL | awk '{print $6}')
RM_SIMPLE=$(grep "Simple repeats" $RM_TBL | awk '{print $4}')
RM_SIMPLE_PCT=$(grep "Simple repeats" $RM_TBL | awk '{print $6}')
RM_UNCLASSIFIED=$(grep "Unclassified:" $RM_TBL | awk '{print $2}')
RM_UNCLASS_PCT=$(grep "Unclassified:" $RM_TBL | awk '{print $5}')

# --- Generate report date ---
REPORT_DATE=$(date "+%B %d, %Y %H:%M")

cat > $report << HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Plestiodon longirostris Genome Assembly Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; color: #333; }
        h1 { color: #2c3e50; border-bottom: 3px solid #2c3e50; padding-bottom: 10px; }
        h2 { color: #34495e; border-bottom: 1px solid #bdc3c7; padding-bottom: 5px; margin-top: 40px; }
        h3 { color: #7f8c8d; }
        .summary-box { background: white; border-radius: 8px; padding: 20px; margin: 20px 0;
                       box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .metric-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; margin: 20px 0; }
        .metric-card { background: white; border-radius: 8px; padding: 15px; text-align: center;
                       box-shadow: 0 2px 4px rgba(0,0,0,0.1); border-top: 4px solid #3498db; }
        .metric-card.good { border-top-color: #27ae60; }
        .metric-card.warn { border-top-color: #f39c12; }
        .metric-value { font-size: 2em; font-weight: bold; color: #2c3e50; }
        .metric-label { font-size: 0.9em; color: #7f8c8d; margin-top: 5px; }
        table { width: 100%; border-collapse: collapse; background: white;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1); border-radius: 8px; overflow: hidden; }
        th { background: #2c3e50; color: white; padding: 12px; text-align: left; }
        td { padding: 10px 12px; border-bottom: 1px solid #ecf0f1; }
        tr:hover { background: #f8f9fa; }
        tr:last-child td { border-bottom: none; }
        .good { color: #27ae60; font-weight: bold; }
        .warn { color: #f39c12; font-weight: bold; }
        .pipeline-step { display: flex; align-items: center; margin: 10px 0; }
        .pipeline-step .step-num { background: #2c3e50; color: white; border-radius: 50%;
                                    width: 30px; height: 30px; display: flex; align-items: center;
                                    justify-content: center; font-weight: bold; margin-right: 15px;
                                    flex-shrink: 0; }
        .pipeline-step .step-text { flex: 1; }
        .toc { background: white; border-radius: 8px; padding: 20px; margin: 20px 0;
               box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .toc a { color: #2980b9; text-decoration: none; display: block; padding: 3px 0; }
        .toc a:hover { text-decoration: underline; }
    </style>
</head>
<body>

<h1>?? Plestiodon longirostris Genome Assembly Report</h1>
<p>Generated: $REPORT_DATE</p>
<p>Assembly pipeline: Flye (Nanopore) ? Medaka polish ? RagTag scaffold ? Pilon (short-read polish) ? RepeatMasker ? Liftoff annotation</p>

<div class="toc summary-box">
    <h3>Contents</h3>
    <a href="#overview">1. Assembly Overview</a>
    <a href="#busco">2. BUSCO Gene Completeness</a>
    <a href="#quast">3. QUAST Assembly Statistics</a>
    <a href="#chromosomes">4. Chromosome Summary</a>
    <a href="#repeats">5. Repeat Content</a>
    <a href="#annotation">6. Gene Annotation</a>
    <a href="#pipeline">7. Pipeline Summary</a>
    <a href="#software">8. Software Versions</a>
</div>

<h2 id="overview">1. Assembly Overview</h2>
<div class="metric-grid">
    <div class="metric-card good">
        <div class="metric-value">1.496 Gb</div>
        <div class="metric-label">Final Assembly Size</div>
    </div>
    <div class="metric-card good">
        <div class="metric-value">13</div>
        <div class="metric-label">Chromosome Scaffolds</div>
    </div>
    <div class="metric-card good">
        <div class="metric-value">~224 Mb</div>
        <div class="metric-label">Scaffold N50</div>
    </div>
    <div class="metric-card good">
        <div class="metric-value">${BUSCO_C_PCT}%</div>
        <div class="metric-label">BUSCO Completeness</div>
    </div>
    <div class="metric-card good">
        <div class="metric-value">${RM_TOTAL_PCT}%</div>
        <div class="metric-label">Repeat Content</div>
    </div>
    <div class="metric-card good">
        <div class="metric-value">45.68%</div>
        <div class="metric-label">GC Content</div>
    </div>
</div>

<h2 id="busco">2. BUSCO Gene Completeness</h2>
<div class="summary-box">
<p>BUSCO assessed using the <strong>squamata_odb12</strong> lineage dataset ($BUSCO_TOTAL BUSCOs).</p>
<table>
    <tr>
        <th>Assembly Stage</th>
        <th>Complete (C)</th>
        <th>Single-copy (S)</th>
        <th>Duplicated (D)</th>
        <th>Fragmented (F)</th>
        <th>Missing (M)</th>
        <th>Internal stop codons</th>
    </tr>
    <tr>
        <td>RagTag scaffold</td>
        <td class="good">98.5% (11,128)</td>
        <td>98.2% (11,096)</td>
        <td>0.3% (32)</td>
        <td>0.4% (46)</td>
        <td>1.1% (120)</td>
        <td class="warn">9.1%</td>
    </tr>
    <tr>
        <td>Pilon polished (final)</td>
        <td class="good">${BUSCO_C_PCT}% ($BUSCO_COMPLETE)</td>
        <td>${BUSCO_S_PCT}% ($BUSCO_SINGLE)</td>
        <td>${BUSCO_D_PCT}% ($BUSCO_DUP)</td>
        <td>${BUSCO_F_PCT}% ($BUSCO_FRAG)</td>
        <td>${BUSCO_M_PCT}% ($BUSCO_MISSING)</td>
        <td class="warn">${BUSCO_STOP_PCT}% ($BUSCO_STOP)</td>
    </tr>
</table>
</div>

<h2 id="quast">3. QUAST Assembly Statistics</h2>
<div class="summary-box">
<table>
    <tr>
        <th>Metric</th>
        <th>Flye Contigs</th>
        <th>RagTag Scaffold</th>
        <th>Pilon Polished</th>
    </tr>
    <tr><td>Total length (bp)</td><td>$Q_LEN_FLY</td><td>$Q_LEN_RAG</td><td>$Q_LEN_POL</td></tr>
    <tr><td>N50</td><td>$Q_N50_FLY</td><td>$Q_N50_RAG</td><td>$Q_N50_POL</td></tr>
    <tr><td>L50</td><td>$Q_L50_FLY</td><td>$Q_L50_RAG</td><td>$Q_L50_POL</td></tr>
    <tr><td>auN</td><td>$Q_AUN_FLY</td><td>$Q_AUN_RAG</td><td>$Q_AUN_POL</td></tr>
    <tr><td>NA50</td><td>$Q_NA50_FLY</td><td>$Q_NA50_RAG</td><td>$Q_NA50_POL</td></tr>
    <tr><td>Genome fraction (%)</td><td>$Q_GF_FLY</td><td>$Q_GF_RAG</td><td class="good">$Q_GF_POL</td></tr>
    <tr><td>GC (%)</td><td>$Q_GC_FLY</td><td>$Q_GC_RAG</td><td>$Q_GC_POL</td></tr>
    <tr><td>N's per 100 kbp</td><td>$Q_NS_FLY</td><td>$Q_NS_RAG</td><td class="good">$Q_NS_POL</td></tr>
    <tr><td>Indels per 100 kbp</td><td>$Q_INDEL_FLY</td><td>$Q_INDEL_RAG</td><td class="good">$Q_INDEL_POL</td></tr>
    <tr><td>Misassemblies</td><td>$Q_MIS_FLY</td><td>$Q_MIS_RAG</td><td>$Q_MIS_POL</td></tr>
    <tr><td>Largest sequence (bp)</td><td>$Q_LARGE_FLY</td><td>$Q_LARGE_RAG</td><td>$Q_LARGE_POL</td></tr>
</table>
</div>

<h2 id="chromosomes">4. Chromosome Summary</h2>
<div class="summary-box">
<p>Scaffolded against <em>Plestiodon fasciatus</em> (rPleFas1.1, 13 chromosomes) using RagTag.
99.3% of assembly sequence placed onto 13 chromosome scaffolds.</p>
<table>
    <tr>
        <th>Chromosome</th>
        <th><em>P. longirostris</em> (bp)</th>
        <th><em>P. fasciatus</em> (bp)</th>
        <th>Difference (Mb)</th>
    </tr>
    <tr><td>chr1</td><td>295,720,443</td><td>304,269,845</td><td>-8.5</td></tr>
    <tr><td>chr2</td><td>253,231,868</td><td>263,600,637</td><td>-10.4</td></tr>
    <tr><td>chr3</td><td>223,987,140</td><td>227,050,938</td><td>-3.1</td></tr>
    <tr><td>chr4</td><td>207,062,001</td><td>212,007,450</td><td>-4.9</td></tr>
    <tr><td>chr5</td><td>164,214,746</td><td>166,278,287</td><td>-2.1</td></tr>
    <tr><td>chr6</td><td>110,878,837</td><td>119,429,676</td><td>-8.6</td></tr>
    <tr><td>chr7</td><td>54,763,817</td><td>56,584,554</td><td>-1.8</td></tr>
    <tr><td>chr8</td><td>46,795,637</td><td>48,911,944</td><td>-2.1</td></tr>
    <tr><td>chr9</td><td>32,914,195</td><td>35,513,580</td><td>-2.6</td></tr>
    <tr><td>chr10</td><td>23,532,053</td><td>25,995,680</td><td>-2.5</td></tr>
    <tr><td>chr11</td><td>24,075,819</td><td>25,905,858</td><td>-1.8</td></tr>
    <tr><td>chr12</td><td>23,951,388</td><td>25,656,153</td><td>-1.7</td></tr>
    <tr><td>chr13</td><td>23,861,118</td><td>24,129,074</td><td>-0.3</td></tr>
    <tr style="font-weight:bold; background:#f8f9fa;">
        <td>Total placed</td><td>1,484,988,062</td><td>1,535,333,676</td><td>-50.3</td>
    </tr>
</table>
<p>Unplaced contigs: 2,566 sequences covering ~10.1 Mb</p>
</div>

<h2 id="repeats">5. Repeat Content</h2>
<div class="summary-box">
<p>Repeat masking performed using RepeatMasker with a combined library of de novo repeats
(RepeatModeler, 1,879 families) and Squamata Dfam families (116,078 sequences).</p>
<table>
    <tr>
        <th>Repeat Class</th>
        <th>Length (bp)</th>
        <th>% Genome</th>
    </tr>
    <tr><td>Retroelements (total)</td><td>$RM_RETROELEMENTS</td><td>${RM_RETRO_PCT}%</td></tr>
    <tr><td>&nbsp;&nbsp;SINEs</td><td>$RM_SINES</td><td>${RM_SINES_PCT}%</td></tr>
    <tr><td>&nbsp;&nbsp;LINEs</td><td>$RM_LINES</td><td>${RM_LINES_PCT}%</td></tr>
    <tr><td>&nbsp;&nbsp;LTR elements</td><td>$RM_LTR</td><td>${RM_LTR_PCT}%</td></tr>
    <tr><td>DNA transposons</td><td>$RM_DNA</td><td>${RM_DNA_PCT}%</td></tr>
    <tr><td>Simple repeats</td><td>$RM_SIMPLE</td><td>${RM_SIMPLE_PCT}%</td></tr>
    <tr><td class="warn">Unclassified</td><td>$RM_UNCLASSIFIED</td><td class="warn">${RM_UNCLASS_PCT}%</td></tr>
    <tr style="font-weight:bold;"><td>Total masked</td><td>${RM_TOTAL_BP} bp</td><td class="good">${RM_TOTAL_PCT}%</td></tr>
</table>
<p><strong>Note:</strong> The high unclassified fraction (~33.8%) likely reflects novel or lineage-specific
transposable elements in <em>P. longirostris</em> not represented in current Squamata repeat databases.</p>
</div>

<h2 id="annotation">6. Gene Annotation</h2>
<div class="summary-box">
<p>Annotation transferred from <em>Plestiodon fasciatus</em> (rPleFas1.1) using Liftoff.</p>
<table>
    <tr>
        <th>Stage</th>
        <th>Reference Genes</th>
        <th>Lifted Genes</th>
        <th>Transfer Rate</th>
        <th>Unmapped</th>
    </tr>
    <tr>
        <td>RagTag scaffold (unmasked)</td>
        <td>$LIFTOFF_REF_GENES</td>
        <td>$LIFTOFF_SCAFFOLD_GENES</td>
        <td class="good">${LIFTOFF_SCAFFOLD_PCT}%</td>
        <td>$LIFTOFF_SCAFFOLD_UNMAPPED</td>
    </tr>
    <tr>
        <td>Pilon polished masked (final)</td>
        <td>$LIFTOFF_REF_GENES</td>
        <td>$LIFTOFF_POLISHED_GENES</td>
        <td class="good">${LIFTOFF_POLISHED_PCT}%</td>
        <td>$LIFTOFF_POLISHED_UNMAPPED</td>
    </tr>
</table>
<p>Unmapped genes distributed proportionally across all 13 chromosomes, consistent with
uniform background sequence divergence rather than systematic assembly gaps.</p>
</div>

<h2 id="pipeline">7. Pipeline Summary</h2>
<div class="summary-box">
    <div class="pipeline-step">
        <div class="step-num">1</div>
        <div class="step-text"><strong>Flye assembly</strong> — Nanopore long reads assembled with Flye.
        Output: ~13,115 contigs, 1.494 Gb, N50 333,826 bp</div>
    </div>
    <div class="pipeline-step">
        <div class="step-num">2</div>
        <div class="step-text"><strong>Medaka polishing</strong> — Nanopore-based error correction.</div>
    </div>
    <div class="pipeline-step">
        <div class="step-num">3</div>
        <div class="step-text"><strong>QUAST + BUSCO (contigs)</strong> — Quality assessment.
        99.967% genome fraction, 45.67% GC, 76 misassemblies.</div>
    </div>
    <div class="pipeline-step">
        <div class="step-num">4</div>
        <div class="step-text"><strong>RagTag scaffolding</strong> — Reference-guided scaffolding against
        <em>P. fasciatus</em> (rPleFas1.1). 99.3% sequence placed onto 13 chromosomes.
        N50 improved from 333 kb to 224 Mb.</div>
    </div>
    <div class="pipeline-step">
        <div class="step-num">5</div>
        <div class="step-text"><strong>Liftoff annotation (scaffold)</strong> — $LIFTOFF_SCAFFOLD_GENES
        of $LIFTOFF_REF_GENES genes transferred (${LIFTOFF_SCAFFOLD_PCT}%).</div>
    </div>
    <div class="pipeline-step">
        <div class="step-num">6</div>
        <div class="step-text"><strong>RepeatModeler</strong> — De novo repeat library: 1,879 families.</div>
    </div>
    <div class="pipeline-step">
        <div class="step-num">7</div>
        <div class="step-text"><strong>RepeatMasker</strong> — Combined de novo + Squamata Dfam library
        (116,078 sequences). ${RM_TOTAL_PCT}% of genome masked.</div>
    </div>
    <div class="pipeline-step">
        <div class="step-num">8</div>
        <div class="step-text"><strong>Pilon polishing</strong> — Short-read polishing using 333 Illumina
        paired-end datasets from 198 <em>P. longirostris</em> individuals, subsampled to ~100x coverage per chromosome.</div>
    </div>
    <div class="pipeline-step">
        <div class="step-num">9</div>
        <div class="step-text"><strong>RepeatMasker (polished)</strong> — Final repeat masking of polished assembly.
        ${RM_TOTAL_PCT}% masked.</div>
    </div>
    <div class="pipeline-step">
        <div class="step-num">10</div>
        <div class="step-text"><strong>Liftoff annotation (final)</strong> — $LIFTOFF_POLISHED_GENES
        genes transferred to polished masked assembly (${LIFTOFF_POLISHED_PCT}%).</div>
    </div>
</div>

<h2 id="software">8. Software Versions</h2>
<div class="summary-box">
<table>
    <tr><th>Tool</th><th>Version</th><th>Purpose</th></tr>
    <tr><td>Flye</td><td>$FLYE_VER</td><td>Nanopore genome assembly</td></tr>
    <tr><td>Medaka</td><td>$MEDAKA_VER</td><td>Nanopore polishing</td></tr>
    <tr><td>RagTag</td><td>$RAGTAG_VER</td><td>Reference-guided scaffolding</td></tr>
    <tr><td>QUAST</td><td>$QUAST_VER</td><td>Assembly quality assessment</td></tr>
    <tr><td>BUSCO</td><td>$BUSCO_VER</td><td>Gene completeness assessment</td></tr>
    <tr><td>minimap2</td><td>$MINIMAP2_VER</td><td>Sequence alignment</td></tr>
    <tr><td>RepeatModeler</td><td>$REPEATMODELER_VER</td><td>De novo repeat library</td></tr>
    <tr><td>RepeatMasker</td><td>$REPEATMASKER_VER</td><td>Repeat masking</td></tr>
    <tr><td>Liftoff</td><td>$LIFTOFF_VER</td><td>Annotation transfer</td></tr>
    <tr><td>Pilon</td><td>$PILON_VER</td><td>Short-read polishing</td></tr>
</table>
</div>

</body>
</html>
HTML

echo "--- Report generated ---"
echo "Report saved to: $report"