# Artificial metagenomes #

For the glory of Matt Stairs.

So you want to make some artificial metagenomes....

*Brought to you by* Ryan Moore, Zebulon T. Johsnon & K. A. Ezra Ashdowne

*2 June 2014*

## Get the data from virome ##

### Taxonomy hits ###

- Go to virome and click browse.
- Pick a library.
- Click on the virus part of the far right pie chart.
- Click download search sequences at the bottom.

### GC data ###

- Click statistics
- Pick your environment
- Pick your library
- Scroll to the bottom to the GC histogram
- Cmd-click anywhere on a bar to download the histogram

## Parse the data ##

You will get a nice CSV file. The last row in this file is species. We
want to count the number of times each species gets a hit.

Excel is naughty, so first convert the line endings.

	convert_line_endings.py virome_info.csv

Next, run `count_species.rb` like so:

    count_species.rb virome_info.csv > species_hit_counts.csv

Add the community abundance.

	add_community_abundance.rb species_hit_counts.csv > species_abundance.csv

Aside: you can get the ranks of these with

	ruby ranks.rb species_abundance.csv > species_abundance.ranks.csv

Note that you shouldn't use this output in the pipeline as the rest of
the pipeline doesn't accept this file. *TODO: update the pipeline to
use this file.*

To figure out which of these species has an entry in refseq viral
genomes, run

	artificial_metagenome.rb refseq_viral_genomes.fa species_abundance.csv > my_funny_artm_file.tab.txt

This will give you a file with number of hits, abundance, gc%,
organism name, refseq header, reseq sequnce. To get something easy to
work with while choosing the sequences you want, do this

	cut -f1,2,3,4,5 my_funny_artm_file.tab.txt | sort -n > import_me_into_excel_or_something.tab.txt

Note that the community abundance reflects the original percantage of
that organism from the virome tax hits. The `artificial_metagenome.rb`
script reduces the complexity to only those who are represented in
RefSeq, but keeps the original community abundance. So, don't be
alarmed when you are missing ranks!

## Select the genomes you want ##

Double check that the output from the cut is a close approx of the
original distribution. If it is then great! If not, well, not sure
what to do yet.

Anyway, take the number of genomes you want, say 10, and divide that
by the largest rank. In this case it was 183. So, to pick genomes so
you have a similar distribution, you need to select a genome every 18
or so ranks. You can get this from R like so,

	seq(from=1, to=183, by=19)
	# => 1  20  39  58  77  96 115 134 153 172

Note that you may want to take the last entry, here its 172 and move
it somewhere between the first and the second. It'll make your curve
look spiffy.

Now they key is picking the right genomes. Maybe you want to get a
wide range of GC, or a narrow range, or only organisms of a certain
type. So pick things that meet your criteria as long as they are near
the rank you need. I.e., as long as you pick something with a rank
pretty close to the ones that the `seq` function spits out, you should
have the distribution you are looking for.

Since we want the community to be as similar to the real one, we are
going to base our GC on the histogram from virome. Since we only want
ten genomes, it won't be very exact but that's okay, just get it
close.

To do this, import the histogram into excel and get the
percentages. From those you can figure out how many genomes you need
at each GC bin.

## Make the fasta files ##

First, make a file with the names of the organisms you picked. Say we
call it `keep_these.txt`. It will look something like this:

    Puniceispirillum phage HMO-2011
    Prochlorococcus phage P-SSM2
    Pelagibacter phage HTVC011P
    Cyanophage S-TIM5
    Cellulophaga phage phi14:2
    Cyanophage KBS-P-1A
    Sulfitobacter phage pCB2047-C
    Cyanophage NATL2A-133
    Pseudomonas phage tf
    Klebsiella phage JD001

Now, run

	artificial_metagenome_to_fasta.rb keep_these.txt my_funny_artm_file.tab.txt

The output will be one fasta file for each organism. It will have the
name of the organism as the file name. In it will be simply that
sequence in fasta format with the header from RefSeq. Yes!

## Grind them up! ##

You'll need a grinder settings file. Here is one for Illumina:

    -mutation_dist poly4 3e-3 3.3e-8
    -read_dist 250 uniform 10
    -mate_orientation FR
    -insert_dist 600 normal 10
    -mutation_ratio 100 1
    # good residues get 38 G(ood), residues from insertion or sub get 12 (-)
    -qual_levels 38 12
    -fastq_output 1

And in the folder where you put your fasta files, with the lovely
`grind_me.sh` script, we run

	grind_me.sh first_organism.fa num_reads

Run this for each fasta file, replacing `num_reads` with the number of
reads you need from each genome. Remeber you calculated this in excel!

For easy-ness (or perhaps difficulty) run `grind_me_wrapper.sh`. TODO:
make this step easier.

## Formatting the Grinder output ##

You'll have a bunch of files from Grinder. Take all the fastq files it
spits out and cat them together. Do something like

	cat *fastq > all.fastq

Then, on the output, run

	split_paried_end_fastq.rb all.fastq

This spits out `all.1.fastq` and `all.2.fastq`, which contain the
first and second of the pairs respectively.

### Gotchas ###

If you give an odd number of reads and want paried end data, you will always get one unpaired read.

If this happens, here is how to fix it.

First grep out all the read names from the split fastq files.

	grep "^@[0-9]+/1 " all.1.fastq | cut -f1 -d " " | sed 's|1$||;s|[/@]||g' > read_names.1.txt
	grep "^@[0-9]+/2 " all.2.fastq | cut -f1 -d " " | sed 's|2$||;s|[/@]||g' > read_names.2.txt

Now, `read_names.1.txt` will have more lines than `read_names.2.txt`, so run

	diff read_names.2.txt read_names.1.txt

You'll get output that looks something like this:

	54760a54761
	> 9451
	94503a94505
	> 3496
	150946a150949
	> 56444

It's telling you that `read_names.2.txt` has three extra sequences
`9451`, `3496`, and `56444`. So now grep these out of your fastq file.

	grep "^@9451/|^@3496/|^@56444/" all.fastq

Go through the output and whenever you see something without a
matching pair, that's the sequence you want to take out. E.g., if you
see `@9451/1` but not `@9451/2`.

Copy these into a text file or something and then grep them out of the
`all.fastq` file. You could just grab them from the .1 file, but then
you'd have mate pair files that were different from the file you made
them from. Woof.


	cp all.fastq all.clean.fastq
	grep -n -A3 "^@3496/1.*Klebsiella phage JD001, complete genome\"$" all.clean.fastq

Run something like that for each of the sequences that need to be
deleted. The output will tell you which lines to delete with `sed` in
the next step.

Say the output of one of your greps started with

	5:foo
	6-bar
	7-baz
	8-quux

Then run `sed -i '5,8d' all.clean.fastq` to remove the lines. Repeat
for each problem you had.

Finally run

	split_paried_end_fastq.rb all.clean.fastq

#### Headers too long ####

The headers are too long as Grinder puts the errors in the
header. (The max is 256 chars.) (TODO: find a way to deal with this
upstream.) You can fix this by running

	sed -i 's/ errors=.* description=/ description=/' all.clean.1.fastq
	sed -i 's/ errors=.* description=/ description=/' all.clean.1.fastq

