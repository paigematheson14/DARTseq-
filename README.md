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
