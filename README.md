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

# 5. 





















  stygia:
  
