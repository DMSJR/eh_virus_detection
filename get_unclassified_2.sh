#!/bin/bash


# Paths
FASTQ_PATH="../bowtie2"       # where the Bowtie2 files are
IDS_PATH="."                  # where the *_unclassified_ids.txt lists are
OUT_PATH="."                  # output folder for FASTQs

# Loop through the ID lists
for ids in ${IDS_PATH}/*_unclassified_ids.txt; do
    sample=$(basename "$ids" _unclassified_ids.txt)

    echo "🔎 Processing $sample ..."

    fq1="$FASTQ_PATH/${sample}_bt2_filtered.1"
    fq2="$FASTQ_PATH/${sample}_bt2_filtered.2"

    if [[ ! -f "$fq1" || ! -f "$fq2" ]]; then
        echo "❌ FASTQs not found for $sample"
        continue
    fi

    # Extract unclassified reads
    seqtk subseq "$fq1" "$ids" > "$OUT_PATH/${sample}_unclassified_R1.fastq"
    seqtk subseq "$fq2" "$ids" > "$OUT_PATH/${sample}_unclassified_R2.fastq"

    echo "✅ Generated: ${sample}_unclassified_R1.fastq.gz and ${sample}_unclassified_R2.fastq.gz"
done
