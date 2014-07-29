#!/bin/bash

# written 22 jan 2014
# update 20 june 2014

# USAGE: samtools.sh my_sam_file.sam

sam=$1
bam=${sam%.*}.bam
sorted=${bam%.*}.sorted
bam_sorted=$sorted.bam

echo "/usr/local/samtools-0.1.18/samtools view -b -S -o $bam $sam"
/usr/local/samtools-0.1.18/samtools view -b -S -o $bam $sam

echo "/usr/local/samtools-0.1.18/samtools sort $bam $sorted"
/usr/local/samtools-0.1.18/samtools sort $bam $sorted

echo "/usr/local/samtools-0.1.18/samtools index $bam_sorted"
/usr/local/samtools-0.1.18/samtools index $bam_sorted
