# eh_virus_detection

## Quality Control

The raw files were submitted to **FastQC v0.12.1** for verification before trimming, using the following command:

```bash
fastqc -t 8 {sample}_R1.fq.gz {sample}_R2.fq.gz
```

Next, **fastp v0.23.2** was used for trimming. After testing different parameters and verifying the results with FastQC, the following command was chosen:

```bash
fastp --detect_adapter_for_pe -t 1 -f 1 -T 1 -F 1 -e 20 \
  -i {sample}_R1.fq.gz -I {sample}_R2.fq.gz \
  -o {sample}_1_fastp.fastq -O {sample}_2_fastp.fastq
```

**FastQC** was then used again to verify trimming effectiveness and overall data quality. One sample (**EH-MG-67**) was excluded due to low quality. The first and last base pairs were also removed (as handled by the `-f` and `-F` options above).

```bash
fastqc -t 8 {sample}_1_fastp.fastq {sample}_2_fastp.fastq
```

---

## Host Filtering

**Bowtie2** and **Samtools** were used to filter out host (human) sequences. The reference genome was **GRCh38**.

```bash
bowtie2  -D 20 -R 3 -N 1 -L 20 -x human_genome \
  -1 {sample}_1_fastp.fastq -2 {sample}_2_fastp.fastq \
  --very-sensitive-local --threads 8 -S {sample}_bt2_aligned.sam
```

```bash
samtools view -bS {sample}_bt2_aligned.sam | samtools sort -o {sample}.sorted.bam
```

```bash
samtools view -b -f 12 -F 256 {sample}.sorted.bam > {sample}_nonhuman.bam
```

```bash
samtools fastq -1 {sample}_nonhuman_R1.fastq -2 {sample}_nonhuman_R2.fastq -0 /dev/null -s /dev/null  -n {sample}_nonhuman.bam
```


---

## Taxonomic Classification

**Kraken2 v2.0.7-beta** was used to classify sequences against the database PlusPF:

```bash
srun kraken2 --db kraken2_db \
  --report {sample}_kraken.txt \
  --paired {sample}_nonhuman_R1.fastq {sample}_nonhuman_R2.fastq \
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

The unclassified sequences were extracted using the scripts `get_unclassified_1.sh` and `get_unclassified_2.sh` (available in this repository). All unclassified reads were concatenated into two files with all data (`all_unclassified_R1.fastq` and `all_unclassified_R2.fastq`),  also two groups of files, with samples separated by condition ("lesion"/"non-lesion"), and assembling was also performed for each sample individually, with **MEGAHIT v1.2.9**:

```bash
megahit -1 file_R1.fastq -2 file_R2.fastq -o megahit_output
```


---

## Viral Detection

The assembled contigs were analyzed with **DeepVirFinder v1.0** and **VirSorter2 v2.2.4**:

```bash
python dvf.py -i final.contigs.fa -o results_dvf -l 1000

virsorter run -i final.contigs.fa -w virsorter_output \
  --min-length 1500 --min-score 0.5 --include-groups dsDNAphage,NCLDV,RNA,ssDNA --prep-for-dramv -j 8 all
```

---

