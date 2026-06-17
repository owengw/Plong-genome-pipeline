# /mnt/parscratch/users/bi4og/scripts/genome_pipeline_config.sh
# Edit this for each run, then submit individual scripts with sbatch

export REF_GENOME=/mnt/parscratch/users/bi4og/genome/Pgilberti.fna
export REF_GFF=/mnt/parscratch/users/bi4og/genome/Pgilberti.gff
export REF_NAME=gilberti

export MEDAKA=/mnt/parscratch/users/bi4og/genome/medaka/consensus.fasta
export MERGED_BAM=/mnt/parscratch/users/bi4og/pilon_gilberti/all_illumina_merged.bam
export FOFN=/mnt/parscratch/users/bi4og/nextpolish/sgs.fofn

export SRC=/mnt/parscratch/users/bi4og
export REPEAT_LIB=$SRC/repeat_libraries/combined_repeats.fa
export BUSCO_LINEAGE=squamata_odb12
export N_CHRS=13

export RAGTAG_OUT=$SRC/ragtag_output_${REF_NAME}
export PILON_OUT=$SRC/pilon_${REF_NAME}
export REPEATMASKER_OUT=$SRC/repeatmasker_${REF_NAME}
export LIFTOFF_OUT=$SRC/liftoff_polished_${REF_NAME}
export BUSCO_SCAFFOLD=$SRC/busco_scaffold_${REF_NAME}
export BUSCO_POLISHED=$SRC/busco_polished_${REF_NAME}
export QUAST_SCAFFOLD=$SRC/quast_scaffold_${REF_NAME}
export QUAST_POLISHED=$SRC/quast_polished_${REF_NAME}
export PILON_FASTA=$PILON_OUT/plongirostris_pilon_${REF_NAME}.fasta