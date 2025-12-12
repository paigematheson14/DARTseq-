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
Multiqc results:

Hilli:
- duplication was 84-91% (expected for reduced representation)
- median read length: 62-87 (majority 72-82)
- GC content: 42-58%
- total reads good (0.8-1.3M)
- adapter content: peak cumulative at positions 1.25%, which is low.
- Overrepresented sequences are long motifs starting TGCAG, which is an expected enzyme signature

Verdict: Looks healthy; proceed with light adapter/quality trimming.

  quad:
- Duplication: ~83–95%; a few samples >94% (normal for targeted fragments)
- Median read length: 57–92 bp; a handful around 57–62 bp (shorter) — still fine after trimming.
- %GC: 42–61%; several at the upper end (likely enzyme/fragment selection bias).
- Total reads: roughly ~0.7–1.6 M; one sample is near 0.7 M, which is a bit light compared to the cohort but still usable. 
-Adapter content: very low; peak around 0.31%. 
- Overrepresented sequences: multiple TGCAG… variants across samples — expected.

Verdict: Good overall. If the under‑sequenced sample drives downstream dropout, consider flagging or down‑weighting it.

03_stygia:
-Duplication: ~76–92%; one sample around 76% (slightly lower than most, but not a problem).
-Median read length: 67–92 bp. 
-%GC: 43–58% (coherent range). 
- Total reads: ~0.9–1.4 M per sample.
- Adapter content: low; peak around 1.16%. 
- Overrepresented sequences: enzyme‑signature TGCAG… motifs again, as expected.

Verdict: Solid; standard trimming should suffice.

vicina:
Duplication: Very high (87–92%) — expected for reduced‑representation libraries.
Median read length: Mostly 67–92 bp, with one short outlier at 57 bp. 
%GC: Narrow range (42–55%) — consistent with enzyme bias.
Total reads: ~0.9–1.3 M per sample — solid coverage for DArT pipelines. 
Adapter content: Very low (peak cumulative ≈ 0.39–0.43%), so only minimal trimming needed.
Overrepresented sequences: All start with TGCAG…, matching restriction‑site motifs (normal for DArTseq).

verdict: pretty good 

# 3. I'll do some light trimming to remove adapters and low-quality bases 

this avoids downstream mapping artifacts and false SNPs

```
fastp -i sample.fastq.gz -o sample.trimmed.fastq.gz \
      --detect_adapter_for_pe \
      --cut_tail --cut_mean_quality 20 \
      --length_required 50 \
```

# 4. Then re-run fastqc and multiqc to see if it improved

It did :) the duplication was slightly less and the median bp length improved.

# 5. I used bwa to index the fastq reads to my reference genome for stygia, hilli, and vicina (because those genomes were okay, quad was bad)
i made a bash file like this for each of my species. the samples list is just a list of all of the samples (for looping reasons). this script aligns and sorts reads against the reference genomes.

```
#!/usr/bin/env bash

# --- Config ---
GENOME_FA="/nesi/project/uow03920/09_dart/05_reference/01_hilli_filtered_contaminants.fasta"
BWA_PREFIX="/nesi/project/uow03920/09_dart/05_reference/bwa/01_hilli"
SAMPLES_LIST="01_ids.txt"       # one sample per line
TRIM_DIR="/nesi/project/uow03920/09_dart/03_trimming/01_hilli"
OUT_DIR="/nesi/project/uow03920/09_dart/06_bwa/mem/01_hilli"

# --- Index reference if missing ---
if [[ ! -f "${BWA_PREFIX}.bwt" ]]; then
    echo "Indexing genome..."
    bwa index -p "${BWA_PREFIX}" "${GENOME_FA}" &> "${OUT_DIR}/bwa_index.log"
fi

# --- Loop over samples ---
while read -r sample; do
    [[ -z "$sample" ]] && continue

    echo "Working with ${sample}"

    FASTQ="${TRIM_DIR}/${sample}.FASTQ.gz.trimmed.fastq.gz"
    BAM="${OUT_DIR}/${sample}.bam"

    if [[ ! -f "$FASTQ" ]]; then
        echo "Warning: FASTQ not found for ${sample}, skipping."
        continue
    fi

    # Read group (escaped tabs)
    RG="@RG\tID:${sample}\tSM:${sample}\tPL:ILLUMINA\tLB:DArTseq"

    # Align and sort
    bwa mem -t 10 -M -R "$RG" "$BWA_PREFIX" "$FASTQ" \
        | samtools view -bS - \
        | samtools sort -@ 10 -o "$BAM"

    # Index BAM
    samtools index "$BAM"

    # Optional: mapping stats
    samtools flagstat "$BAM"

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

cd ../;
done
```

# quadrimaculata - the devil that you are 
This species likes to make my life hard. because the reference genome I have is bad, highly contiguous, i will do variant calling denovo, still using stacks. First I have to trim the reads to be the same length which is a requirement for ustacks algorithims. 

(RAD/TAG sequences should all be the same length after restriction digest and sequencing. Sometimes reads are shorter due to sequencing errors or incomplete reads, adapter contamination, trimming (e.g., quality trimming). Stacks detects that reads aren’t uniform and stops to avoid misalignments.

I used cutadapt to trim sequences, and i trimmed to 90bp because that was the peak for all of the samples (i.e., most reads had 90bp)

```
for f in *.trimmed.fixed.fastq.gz; do     echo "Trimming $f to 90 bp...";     cutadapt -l 90 -o "${f%.fastq.gz}.trimmed90.fastq.gz" "$f" > "${f%.fastq.gz}.cutadapt90.log"; done
```

















  stygia:
  
