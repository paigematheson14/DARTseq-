# DARTseq-


# 1. 

I got raw data from DArTseq. DArTseq does initial demultiplexing and barcode trimming. I downloaded all of the fastq files and put them into individual folders based on each sample barcode that was provided by DARTseq

# 2.

I looked at the quality of the fastq files using FASTqc and then used multiqc to look at them comparatively for each species

```
ml FastQC
ml MultiQC

fastqc *.fastq.gz
multiqc .
```
verdict: pretty good 

# 3. I'll do some very conservative trimming to remove low-quality bases 

```
        fastp \
            -i "$file" \
            -o "../02_filter/${i}/${filename}.trimmed.fastq.gz" \
            --cut_tail \
            --cut_mean_quality 20 \
            --length_required 50

```

# 4. Then re-run fastqc and multiqc to see if it improved

It did :) the duplication was slightly less and the median bp length improved.

# 5. I used bwa to index the fastq reads to my reference genomes
i made a bash file like this for each of my species. the samples list is just a list of all of the samples (for looping reasons). this script aligns and sorts reads against the reference genomes.

```
#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$OUT_DIR"

while read -r sample; do

    [[ -z "$sample" ]] && continue

    FASTQ="${TRIM_DIR}/${sample}.trimmed.fastq.gz"
    BAM="${OUT_DIR}/${sample}.bam"

    [[ ! -f "$FASTQ" ]] && {
        echo "Missing $FASTQ"
        continue
    }

    RG="@RG\tID:${sample}\tSM:${sample}\tPL:ILLUMINA\tLB:DArTseq"

    bwa mem -t 10 -M -R "$RG" "$BWA_PREFIX" "$FASTQ" \
        | samtools sort -@ 10 -o "$BAM"

    samtools index "$BAM"

    samtools flagstat "$BAM" \
        > "${OUT_DIR}/${sample}.flagstat.txt"

done < "$SAMPLES_LIST"
```

# variant calling

I used populations from Stacks to variant call for stygia, hilli, and vicina. the --vcf flag makes the output a vcf file. very easy :)

```
#!/bin/bash
#SBATCH --account=uow03920
#ATCH --job-name=variant_calling
#SBATCH --time=1:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=5G
#SBATCH --mail-type=ALL
#SBCH --mail-user=paige.matheson14@gmail.com
#SBATCH --output stacks.out    # save the output into a file
#SBATCH --error stacks.err     # save the error output into a file


module purge
module load Stacks

for i in 01_hilli 03_stygia 04_vicina; do

cd ${i}

populations -P ./ -M ${i}_pops.txt --vcf


