# eh_virus_detection

## Quality Control

The raw files were submitted to **FastQC v0.12.1** for verification before trimming, using the following command:

```bash
fastqc -t 8 {sample}_R1.fq.gz {sample}_R2.fq.gz
```

Next, **fastp v0.23.2** was used for trimming. After testing different parameters and verifying the results with FastQC, the following command was chosen:

```bash
fastp --detect_adapter_for_pe -t 1 -f 1 -T 1 -F 1 \
  -i {sample}_R1.fq.gz -I {sample}_R2.fq.gz \
  -o {sample}_1_fastp.fastq -O {sample}_2_fastp.fastq
```

**FastQC** was then used again to verify trimming effectiveness and overall data quality. One sample (**EH-MG-67**) was excluded due to low quality. The first and last base pairs were also removed (as handled by the `-f` and `-F` options above).

```bash
fastqc -t 8 {sample}_1_fastp.fastq {sample}_2_fastp.fastq
```

---

## Host Filtering

**Bowtie2** was used to filter out host (human) sequences. The reference genome was **GRCh38**.

```bash
bowtie2 -x human_genome \
  -1 {sample}_1_fastp.fastq -2 {sample}_2_fastp.fastq \
  --un-conc {sample}_bt2_filtered
```

---

## Taxonomic Classification

**Kraken2 v2.0.7-beta** was used to classify sequences against the database PlusPF:

```bash
srun kraken2 --db kraken2_db \
  --report {sample}_kraken.txt \
  --paired {sample}_bt2_filtered.1 {sample}_bt2_filtered.2 \
  --output {sample}_kraken.out
```

**Bracken v3.1** was then used to re-estimate taxon abundances with a Bayesian model:

```bash
bracken -d kraken2_db \
  -i {sample}_kraken.txt \
  -o {sample}_bracken.txt \
  -r 150 -l S
```

---

## Assembly of Unclassified Reads

The unclassified sequences were extracted using the scripts `get_unclassified_1.sh` and `get_unclassified_2.sh` (available in this repository). All unclassified reads were concatenated into two files (`all_unclassified_R1.fastq` and `all_unclassified_R2.fastq`) and assembled with **MEGAHIT v1.2.9**:

```bash
megahit -1 all_unclassified_R1.fastq -2 all_unclassified_R2.fastq -o megahit_output
```

---

## Viral Detection

The assembled contigs were analyzed with **DeepVirFinder v1.0** and **VirSorter2 v2.2.4**:

```bash
python dvf.py -i final.contigs.fa -o results_dvf -l 1000

virsorter run -i final.contigs.fa -w virsorter_output \
  --min-length 1000 --min-score 0.5 -j 8 all
```

---

