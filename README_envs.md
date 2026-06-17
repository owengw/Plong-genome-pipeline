# Conda Environment Setup

This document describes the conda environments required to run the pipeline.
All environments were run on the University of Sheffield Stanage HPC cluster.

## Environment locations (Stanage HPC)

| Environment | Path | Tools |
|---|---|---|
| owenspopgen | /mnt/parscratch/users/bi4og/conda_envs/owenspopgen | samtools, bwa, bowtie2, bcftools, trimmomatic, fastqc, chopper, picard |
| repeatmasker | /mnt/parscratch/users/bi4og/conda_envs/repeatmasker | repeatmasker, repeatmodeler |
| pilon | /mnt/parscratch/users/bi4og/conda_envs/pilon | pilon |
| medaka_env | /mnt/parscratch/users/bi4og/conda_envs/medaka_env | medaka |
| ragtag | /mnt/parscratch/users/bi4og/users/bi4og/conda_envs/ragtag | ragtag, minimap2 |
| liftoff | /mnt/parscratch/users/bi4og/users/bi4og/conda_envs/liftoff | liftoff, minimap2 |
| genespace_tools | /mnt/parscratch/users/bi4og/conda_envs/genespace_tools | gffread, orthofinder, GENESPACE (R) |
| orthofinder | /mnt/parscratch/users/bi4og/conda_envs/orthofinder | orthofinder 2.5.5 |
| busco | /mnt/community/Genomics/apps/miniforge/miniforge3/envs/busco | busco (shared cluster env) |
| ont_qc | /mnt/community/Genomics/apps/miniforge/miniforge3/envs/ont_qc | nanoplot, nanocomp, seqkit |

---

## Recreation instructions

If recreating environments from scratch:

### owenspopgen
```bash
conda create -n owenspopgen -c bioconda -c conda-forge \
    samtools=1.22.1 \
    bwa=0.7.19 \
    bowtie2=2.5.5 \
    bcftools=1.22 \
    trimmomatic=0.40 \
    fastqc=0.12.1 \
    chopper=0.12.0 \
    picard=2.20.4
```

### repeatmasker
```bash
conda create -n repeatmasker -c bioconda -c conda-forge \
    repeatmasker=4.2.2 \
    repeatmodeler=2.0.7
```

### pilon
```bash
conda create -n pilon -c bioconda pilon=1.24
```

### medaka
```bash
conda create -n medaka_env -c bioconda -c conda-forge medaka=2.2.1
```

### ragtag
```bash
conda create -n ragtag -c bioconda -c conda-forge \
    ragtag=2.1.0 \
    minimap2=2.30
```

### liftoff
```bash
conda create -n liftoff -c bioconda -c conda-forge \
    liftoff=1.6.3 \
    minimap2=2.24
```

### genespace_tools
```bash
conda create -n genespace_tools -c bioconda -c conda-forge \
    gffread=0.12.9 \
    orthofinder=2.5.5 \
    r-base=4.3.2

# Then install GENESPACE in R
conda activate genespace_tools
Rscript -e "
    install.packages('devtools', repos='https://cloud.r-project.org')
    devtools::install_github('jtlovell/GENESPACE')
"
```

### busco
```bash
conda create -n busco -c bioconda -c conda-forge busco=6.0.0
```

### ont_qc
```bash
conda create -n ont_qc -c bioconda -c conda-forge \
    nanoplot=1.46.2 \
    nanocomp=1.25.6 \
    seqkit
```

---

## MCScanX

MCScanX is not available via conda and must be compiled from source:

```bash
git clone https://github.com/wyp1125/MCScanX.git
cd MCScanX
make
```

## table2asn

table2asn is a standalone NCBI binary — see g26_table2asn_setup.sh which
downloads the binary directly from NCBI FTP.
