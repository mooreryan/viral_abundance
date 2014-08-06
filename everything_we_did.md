# All the junk we did! (in one place) #

## Make mock community ##

See `making_artificial_metagenome.md` for details.

### Estimated coverage ###

In order to evaluate the accuracy of the kmer coverage method, for
each reference, we calculated estimated coverage by

        num_reads * mean_read_len / genome_len

To evaluate the accuracy of GASiC, we simply used the number of reads
that were creating for each genome with the grinding software.

## Assemble reads ##

Note: The kmer parameter sweep assemblies are the 'official'
assemblies now.

### Assembly parameters ###

`/home/moorer/public/artificial_metagenomes/assembly/soapdenovo/param_sweeps/soap.config`

One assemby each for kmers 27 to 127 -> 51 assemblies
- For both uniform grinder reads and simseq reads

## Taxonomic assignment ##

- blastn contigs and scaffolds against the 10 reference genomes

### Blast settings ###

- blastn (Nucleotide-Nucleotide BLAST 2.2.29+)
- evalue 100
- penalty -2
- reward 2
- gapopen 0
- gapextend 4

## Get relative abundance ##

### Sanity checks ###

#### Kmer coverage ####

- checked to see if contig length had an effect on kmer coverage
  - it didnt

#### Recruitment methods ####

- checked GASiC against naive method
- added in 3 extra phage and 3 extra bacteria to try and confuse GASiC
  - 3 phage were closely related to three phage across the rank
    abundance curve
  - 3 bacteria were chosen as hosts for some of 3 phage

