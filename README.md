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

# 3. I'm going to do de novo variant calling on all of the species and then I might align the reads to reference genomes later
1. Clean up and run denovo_map.pl (01_clean_and_test.sl).



