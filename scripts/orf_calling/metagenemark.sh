#!/bin/bash

infile=$1
output="${infile%.*}".metagenemark.gff2

/home/wommacklab/software/MetaGeneMark_linux64/gmhmmp -m /home/wommacklab/software/MetaGeneMark_linux64/MetaGeneMark_v1.mod -o $output -f G -a -d -r $infile

# -m : gene finding parameters
# -o : output file name
# -f : output format GFF2
# -a : show protein sequence of predicting genes
# -d : show nucleotide seq of predicted genes
# -r : use ribosomal binding sites for gene start prediction
