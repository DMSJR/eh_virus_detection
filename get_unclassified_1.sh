#!/bin/bash

# Paths (adjust if needed)
FASTQ_PATH="/temporario2/dmarques/eh_raw/bowtie2"
OUT_PATH="/temporario2/dmarques/eh_raw/kraken2"
OUT_FASTQ_PATH="/temporario2/dmarques/eh_raw/unclassified_reads"

# Loop through all .out files
for out_file in ${OUT_PATH}/*.out; do
    # sample prefix (removes the _kraken.out suffix)
    sample=$(basename "$out_file" _kraken.out)

    echo "Processing $sample ..."

    # generate list of unclassified IDs
    awk '$1=="U"{print $2}' "$out_file" > "$OUT_FASTQ_PATH/${sample}_unclassified_ids.txt"

    if [ ! -s "$OUT_FASTQ_PATH/${sample}_unclassified_ids.txt" ]; then
        echo "⚠️ No unclassified IDs found in $out_file"
        continue
    fi

    echo "✅ Generated: ${sample}_unclassified_R1.fastq.gz and ${sample}_unclassified_R2.fastq.gz"
done
