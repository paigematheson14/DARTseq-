#!/bin/bash -e
#SBATCH --job-name=dart_clean_r80
#SBATCH --account=uow03920
#SBATCH --array=0-3
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=06:00:00
#SBATCH --output=logs/%x_%A_%a.out

# Step 1: symlink raw reads, clean them with process_radtags (60 bp),
#         then run the r80 parameter test (M = n = 1..6) on 12 samples.
# One array task per species.

module purge
module load Stacks   # check the version with: module spider Stacks

BASE=/nesi/nobackup/uow03920/09_dart/02_variant_calling
SPECIES=(hilli quadrimaculata stygia vicina)
FOLDERS=(01_hilli 02_quadrimaculata 03_stygia 04_vicina)
SP=${SPECIES[$SLURM_ARRAY_TASK_ID]}
RAW=/nesi/nobackup/uow03920/09_dart/01_raw_data/${FOLDERS[$SLURM_ARRAY_TASK_ID]}
OUT=$BASE/02_stacks/$SP
POP=$BASE/popmaps
LEN=60

mkdir -p $OUT/raw_links $OUT/cleaned $OUT/r80

# Skip cleaning if it already finished on an earlier run (read_counts.tsv is the last file it writes)
if [ ! -s $OUT/cleaned/read_counts.tsv ]; then

  #add symlinks
  for f in $RAW/*.FASTQ.gz; do
    ln -sf "$f" $OUT/raw_links/$(basename "$f" .FASTQ.gz).fq.gz
  done

  #clean: check PstI cut site to make sure that reads are from a real RAD locus, quality filter (reads with stretches of low quality are dropped and those with uncalled bases, i.e., Ns), -r tries to fix small errors in cut sites, truncate and drop reads shorter than 60 (they all need to be the same length for stacks)
  process_radtags -p $OUT/raw_links -o $OUT/cleaned -i gzfastq \
    --renz_1 pstI -c -q -r -t $LEN --len-limit $LEN

  #count number of reads after cleaning (used to pick which replicate to keep for the technical replicates)
  for f in $OUT/cleaned/*.fq.gz; do
    echo -e "$(basename $f .fq.gz)\t$(( $(zcat $f | wc -l) / 4 ))"
  done | sort -k2,2n > $OUT/cleaned/read_counts.tsv

fi

#this takes 12 individuals from across sites and runs full de novo assembly six times. M is how many differences two reads from the same fly can have and still count as the same locus. n is the same idea but between flies when building the shared catalog of loci. m 3 means that at least three identical reads are needed to start a stack: filters out sequencing errors. r80 is loci found in at least 80% of samples

for M in 1 2 3 4 5 6; do
  mkdir -p $OUT/r80/M$M        # denovo_map.pl will not create its output folder
  denovo_map.pl --samples $OUT/cleaned --popmap $POP/popmap_${SP}_r80test.txt \
    -o $OUT/r80/M$M -M $M -n $M -m 3 -T $SLURM_CPUS_PER_TASK \
    -X "populations: -r 0.8"
done

#summary: polymorphic loci present in >=80% of test samples
echo -e "M\tpolymorphic_r80_loci" > $OUT/r80/r80_summary.tsv
for M in 1 2 3 4 5 6; do
  n=$(grep -v '^#' $OUT/r80/M$M/populations.sumstats.tsv | cut -f1 | sort -u | wc -l)
  echo -e "$M\t$n" >> $OUT/r80/r80_summary.tsv
done
cat $OUT/r80/r80_summary.tsv
