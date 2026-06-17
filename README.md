# Plong-genome-pipeline

Whole-genome assembly, annotation, and comparative genomics pipeline for the Bermuda skink (*Plestiodon longirostris*), a critically endangered lizard endemic to Bermuda.

**Author:** Owen Greenwood ([@owengw](https://github.com/owengw))  
**License:** MIT  

---

## Overview

This repository contains all SLURM batch scripts, R scripts, and configuration files used to assemble, annotate, and analyse the *P. longirostris* genome from Oxford Nanopore Technologies (ONT) long reads and Illumina short reads. The pipeline produces a chromosome-level genome assembly scaffolded against *Plestiodon fasciatus* (rPleFas1.1), with gene annotation via Liftoff and comparative genomics analyses including synteny, genome landscape visualisation, and putative sex chromosome identification.

---

## Data

| Data type | Platform | Reads | Total bases | Coverage |
|---|---|---|---|---|
| Long-read assembly | Oxford Nanopore Technologies | 30,365,589 | 67.56 Gbp | ~45x |
| Short-read polishing | Illumina NovaSeq | ~11,388M paired-end | ~1.67 Tbp | — |

Raw sequencing data are deposited in NCBI SRA under BioProject **[PRJNA accession pending]**.

---

## Assembly Statistics

| Metric | Value |
|---|---|
| Total assembly size | 1.496 Gb |
| Number of sequences | 2,574 |
| Chromosome-level scaffolds | 13 |
| Scaffold N50 | ~224 Mb |
| BUSCO completeness (squamata_odb12) | 98.7% |
| Genes annotated | 30,813 |

---

## Pipeline Overview

```
Raw ONT reads
    │
    ├── g01_nanoplot.sh          QC of raw ONT reads
    ├── g02_chopper.sh           ONT read filtering
    ├── g03_flye.sh              De novo assembly (Flye)
    ├── g04_medaka.sh            ONT polishing (Medaka)
    ├── g05_illumina_qc.sh       Illumina QC (FastQC/Trimmomatic)
    ├── g06_busco.sh             Assembly QC (BUSCO)
    ├── g07_quast.sh             Assembly statistics (QUAST)
    ├── g08_bwa_align.sh         Illumina alignment for polishing
    ├── g09_pilon.sh             Illumina polishing (Pilon)
    ├── g10_ragtag.sh            Scaffolding to P. fasciatus (RagTag)
    ├── g11_busco_scaffolded.sh  Post-scaffolding BUSCO
    ├── g12_repeatmodeler.sh     Repeat library generation (RepeatModeler2)
    ├── g13_repeatmasker.sh      Repeat masking (RepeatMasker)
    ├── g14_liftoff.sh           Gene annotation transfer (Liftoff)
    ├── g15_annotation_qc.sh     Annotation QC and polishing
    │
    ├── Comparative genomics
    │   ├── g16_genespace_prep_fasciatus.sh   Prepare GENESPACE inputs
    │   ├── g17_genespace_prep_gilberti.sh    Prepare GENESPACE inputs
    │   ├── g18_mcscanx.sh                   Synteny block detection
    │   ├── g19_sex_chr_synteny.sh            Putative X chromosome identification
    │   ├── g20_download_species.sh           Download outgroup genomes
    │   ├── g21_genespace.sh                  GENESPACE run
    │   ├── g22_riparian_plot.sh              Riparian synteny plot
    │   ├── g23_genome_density.sh             Genome landscape windows
    │   │
    │   └── R scripts
    │       └── circos_genome_landscape.R     Circos genome landscape figure
    │
    ├── Sex identification
    │   └── p_sex_identification.sh          chrX/autosome coverage ratio analysis
    │
    └── NCBI submission
        ├── g24_fcs_clean.sh                 FCS-GX contamination removal
        ├── g25_ncbi_prep.sh                 Final pre-submission checks
        ├── g26_table2asn_setup.sh           Install table2asn
        └── g27_make_sqn.sh                  Generate .sqn submission file
```

---

## Dependencies

All software was run on the University of Sheffield Stanage HPC cluster using conda environments.

| Tool | Version | conda environment | Reference |
|---|---|---|---|
| NanoPlot | 1.46.2 | ont_qc (shared) | De Coster et al. 2023 |
| NanoComp | 1.25.6 | ont_qc (shared) | De Coster et al. 2023 |
| Chopper | 0.12.0 | owenspopgen | De Coster & Rademakers 2023 |
| Flye | — | — | Kolmogorov et al. 2019 |
| Medaka | 2.2.1 | medaka_env | Oxford Nanopore Technologies |
| RagTag | 2.1.0 | ragtag | Alonge et al. 2022 |
| minimap2 | 2.30 | ragtag | Li 2018 |
| Pilon | 1.24 | pilon | Walker et al. 2014 |
| BUSCO | 6.0.0 | busco (shared) | Manni et al. 2021 |
| QUAST | — | quast | Gurevich et al. 2013 |
| RepeatModeler | 2.0.7 | repeatmasker | Flynn et al. 2020 |
| RepeatMasker | 4.2.2 | repeatmasker | Smit et al. 2013–2015 |
| Liftoff | 1.6.3 | liftoff | Shumate & Salzberg 2021 |
| minimap2 | 2.24 | liftoff | Li 2018 |
| gffread | 0.12.9 | genespace_tools | Pertea & Pertea 2020 |
| OrthoFinder | 2.5.5 | orthofinder | Emms & Kelly 2019 |
| GENESPACE | 1.3.1 | genespace_tools | Lovell et al. 2022 |
| MCScanX | — | compiled from source | Wang et al. 2012 |
| samtools | 1.22.1 | owenspopgen | Danecek et al. 2021 |
| BWA | 0.7.19 | owenspopgen | Li & Durbin 2009 |
| bowtie2 | 2.5.5 | owenspopgen | Langmead & Salzberg 2012 |
| Trimmomatic | 0.40 | owenspopgen | Bolger et al. 2014 |
| FastQC | 0.12.1 | owenspopgen | Andrews 2010 |
| Picard | 2.20.4 | owenspopgen | Broad Institute 2019 |
| bcftools | 1.22 | owenspopgen | Danecek et al. 2021 |
| FCS-GX | 0.5.5 | Galaxy (web) | Astashyn et al. 2024 |
| IQ-TREE | 3.1.1 | — | Minh et al. 2020 |

---

## Repository Structure

```
Plong-genome-pipeline/
├── README.md
├── LICENSE
├── config/
│   └── genome_pipeline_config.sh     Shared path/variable configuration
├── scripts/
│   ├── g01_nanoplot.sh
│   ├── g02_chopper.sh
│   ├── g03_flye.sh
│   ├── g04_medaka.sh
│   ├── g05_illumina_qc.sh
│   ├── g06_busco.sh
│   ├── g07_quast.sh
│   ├── g08_bwa_align.sh
│   ├── g09_pilon.sh
│   ├── g10_ragtag.sh
│   ├── g11_busco_scaffolded.sh
│   ├── g12_repeatmodeler.sh
│   ├── g13_repeatmasker.sh
│   ├── g14_liftoff.sh
│   ├── g15_annotation_qc.sh
│   ├── g16_genespace_prep_fasciatus.sh
│   ├── g17_genespace_prep_gilberti.sh
│   ├── g18_mcscanx.sh
│   ├── g19_sex_chr_synteny.sh
│   ├── g20_download_species.sh
│   ├── g21_genespace.sh
│   ├── g22_riparian_plot.sh
│   ├── g23_genome_density.sh
│   ├── g24_fcs_clean.sh
│   ├── g25_ncbi_prep.sh
│   ├── g26_table2asn_setup.sh
│   ├── g27_make_sqn.sh
│   └── p_sex_identification.sh
├── R/
│   └── circos_genome_landscape.R
└── envs/
    └── README_envs.md                Notes on conda environment setup
```

---

## Usage

### Configuration

All scripts source a shared configuration file defining paths and variables:

```bash
source /path/to/config/genome_pipeline_config.sh
```

Edit `genome_pipeline_config.sh` to set your working directory, reference genome paths, and tool locations before running any scripts.

### Running the pipeline

Scripts are designed to be run sequentially. Each script is a self-contained SLURM job:

```bash
# Example: submit assembly step
sbatch scripts/g03_flye.sh

# Example: chain dependent jobs
JOB1=$(sbatch --parsable scripts/g03_flye.sh)
JOB2=$(sbatch --parsable --dependency=afterok:$JOB1 scripts/g04_medaka.sh)
```

Scripts can also be submitted as a chain using the dependency system — see individual script headers for recommended resource allocations and dependencies.

### Conda environments

Scripts require several conda environments. See `envs/README_envs.md` for setup instructions. Key environments:

```bash
# Population genomics and short-read tools
conda create -n owenspopgen -c bioconda -c conda-forge \
    samtools=1.22.1 bwa=0.7.19 bowtie2=2.5.5 \
    bcftools=1.22 trimmomatic=0.40 fastqc=0.12.1 \
    chopper=0.12.0 picard=2.20.4

# Repeat masking
conda create -n repeatmasker -c bioconda \
    repeatmasker=4.2.2 repeatmodeler=2.0.7

# Polishing
conda create -n pilon -c bioconda pilon=1.24

# Comparative genomics
conda create -n genespace_tools -c bioconda \
    gffread=0.12.9 orthofinder=2.5.5
# Then install GENESPACE in R:
# install.packages("devtools")
# devtools::install_github("jtlovell/GENESPACE")
```

---

## Key Analyses

### Genome assembly
De novo assembly from ONT long reads using Flye, followed by ONT polishing with Medaka and Illumina polishing with Pilon. Chromosome-level scaffolding was performed using RagTag against the *P. fasciatus* reference genome (rPleFas1.1).

### Repeat annotation
Species-specific repeat library generated with RepeatModeler2 and used to soft-mask the assembly with RepeatMasker prior to gene annotation.

### Gene annotation
Genes were transferred from the *P. fasciatus* annotation (GCF_030012295.1) to the *P. longirostris* assembly using Liftoff, followed by manual polishing of the GFF3.

### Comparative genomics
Synteny was assessed across six scincomorphan species using GENESPACE v1.3.1 with OrthoFinder v2.5.5 and MCScanX. The putative X chromosome (chromosome 5) was identified by synteny with *Acritoscincus duperreyi* (GCA_041722995.2), which has well-characterised sex chromosomes.

### Sex chromosome analysis
Coverage of the putative X chromosome (chr5) vs autosomes was calculated for 176 resequenced individuals. No bimodal distribution was observed (mean ratio = 1.03 ± 0.05), suggesting homomorphic sex chromosomes.

---

## References

Alonge M, et al. (2022). Automated assembly scaffolding using RagTag. *Genome Biology*, 23, 258.

Andrews S. (2010). FastQC. http://www.bioinformatics.babraham.ac.uk/projects/fastqc

Astashyn A, et al. (2024). Rapid and sensitive detection of genome contamination at scale with FCS-GX. *Genome Biology*, 25, 60.

Bolger AM, et al. (2014). Trimmomatic: a flexible trimmer for Illumina sequence data. *Bioinformatics*, 30, 2114–2120.

Broad Institute. (2019). Picard toolkit. http://broadinstitute.github.io/picard

Danecek P, et al. (2021). Twelve years of SAMtools and BCFtools. *GigaScience*, 10, giab008.

De Coster W, Rademakers R. (2023). NanoPack2: population-scale evaluation of long-read sequencing data. *Bioinformatics*, 39, btad311.

Emms DM, Kelly S. (2019). OrthoFinder: phylogenetic orthology inference for comparative genomics. *Genome Biology*, 20, 238.

Flynn JM, et al. (2020). RepeatModeler2 for automated genomic discovery of transposable element families. *PNAS*, 117, 9451–9457.

Gurevich A, et al. (2013). QUAST: quality assessment tool for genome assemblies. *Bioinformatics*, 29, 1072–1075.

Hoang DT, et al. (2018). UFBoot2: Improving the ultrafast bootstrap approximation. *Molecular Biology and Evolution*, 35, 518–522.

Kolmogorov M, et al. (2019). Assembly of long, error-prone reads using repeat graphs. *Nature Biotechnology*, 37, 540–546.

Langmead B, Salzberg SL. (2012). Fast gapped-read alignment with Bowtie 2. *Nature Methods*, 9, 357–359.

Li H. (2018). Minimap2: pairwise alignment for nucleotide sequences. *Bioinformatics*, 34, 3094–3100.

Li H, Durbin R. (2009). Fast and accurate short read alignment with Burrows-Wheeler Aligner. *Bioinformatics*, 25, 1754–1760.

Lovell JT, et al. (2022). GENESPACE tracks regions of interest and gene copy number variation across multiple genomes. *eLife*, 11, e78526.

Manni M, et al. (2021). BUSCO update: novel and streamlined workflows along with broader and deeper phylogenetic coverage. *Molecular Biology and Evolution*, 38, 4647–4654.

Minh BQ, et al. (2020). IQ-TREE 2: New models and methods for phylogenetic inference. *Molecular Biology and Evolution*, 37, 1530–1534.

Oxford Nanopore Technologies. Medaka. https://github.com/nanoporetech/medaka

Pertea G, Pertea M. (2020). GFF utilities: GffRead and GffCompare. *F1000Research*, 9, 304.

Shumate A, Salzberg SL. (2021). Liftoff: accurate mapping of gene annotations. *Bioinformatics*, 37, 1639–1643.

Smit AFA, Hubley R, Green P. (2013–2015). RepeatMasker Open-4.0. http://www.repeatmasker.org

Walker BJ, et al. (2014). Pilon: an integrated tool for comprehensive microbial variant detection and genome assembly improvement. *PLoS ONE*, 9, e112963.

Wang Y, et al. (2012). MCScanX: a toolkit for detection and evolutionary analysis of gene synteny and collinearity. *Nucleic Acids Research*, 40, e49.

Guindon S, et al. (2010). New algorithms and methods for estimating maximum-likelihood phylogenies. *Systematic Biology*, 59, 307–321.

---

## Citation

If you use this pipeline, please cite:

> Greenwood O. (2026). Plong-genome-pipeline: whole-genome assembly and annotation pipeline for *Plestiodon longirostris*. GitHub: https://github.com/owengw/Plong-genome-pipeline

---

## Contact

Owen Greenwood — GitHub: [@owengw](https://github.com/owengw)
