#!/bin/bash
#SBATCH --job-name=g26_table2asn_setup
#SBATCH --output=g26_table2asn_setup_%j.log
#SBATCH --mem=8G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --time=00:30:00

# ============================================================
# g26_table2asn_setup.sh
# Download NCBI table2asn standalone binary (not on conda)
# ============================================================

INSTALL_DIR=/mnt/parscratch/users/bi4og/tools/table2asn
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

echo "[$(date)] Downloading table2asn..."

# Linux 64-bit binary from NCBI
wget -O table2asn.gz \
    https://ftp.ncbi.nlm.nih.gov/asn1-converters/by_program/table2asn/linux64.table2asn.gz

gunzip -f table2asn.gz
chmod +x table2asn

echo "[$(date)] Testing installation..."
./table2asn -help | head -5

echo ""
echo "table2asn installed at: $INSTALL_DIR/table2asn"
echo "Add to PATH or call directly in scripts"