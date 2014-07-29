#!/bin/bash -x
## A bash script that runs Velvet
## !! NOTE THAT YOU MUST ADJUST THE HARD-CODED INPUTS !!

## List of Inputs:
## output directory example: /home/dnasko/datastore/metavelvet50
which_velveth=/home/moorer/bin/velveth
which_velvetg=/home/moorer/bin/velvetg
output_directory=$3 #/home/moorer/projects/artificial_metagenomes/soap_info/velvet_test

#### velveth settings ####
# for testing multiple kmer lengths from 35 to 115 in steps of 5 
# note for even multiples, velvet will just decrement and proceed
kmer_size=63
file_type=fastq
read_type=shortPaired
f1=$1 #/home/moorer/projects/artificial_metagenomes/soap_info/test.1.fastq
f2=$1 #/home/moorer/projects/artificial_metagenomes/soap_info/test.2.fastq

#### velvetg settings ####
cutoff_opt=auto
insert_len=600
read_tracking=no
min_contig_lgth=200
exp_cov=auto
out_amos_file=no
#### remove nodes with low long read coverage__enter average coverage cutoff for long reads ####
#### long_cov_cutoff=2 ####

#### run velveth ####
$which_velveth $output_directory $kmer_size -$file_type -$read_type -separate \
    $f1 $f2

#### run velvetg ####
$which_velvetg $output_directory -cov_cutoff $cutoff_opt \
	       -ins_length $insert_len -read_trkg $read_tracking \
	       -min_contig_lgth $min_contig_lgth \
               -amos_file $out_amos_file \
               -exp_cov $exp_cov # \ -long_cov_cutoff $long_cov_cuttoff
