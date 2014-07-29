#!/usr/bin/env ruby

usage = "USAGE: bwa.rb in_db_fasta db_prefix reads_left reads_right"

if ARGV.count < 4
  abort(usage)
end

in_db_fasta = /home/moorer/public/artificial_metagenomes/assembly/soapdenovo/output/linear_grinder/kmer_127/linear_grinder.scafSeq
db_prefix = /home/moorer/public/artificial_metagenomes/serc_stuff/fastas/grinder_output_linear_error/reads/all/BWAsmallVirbase
reads_left = /home/moorer/public/artificial_metagenomes/serc_stuff/fastas/grinder_output_linear_error/reads/all/all.clean.1.fastq
reads_right = /home/moorer/public/artificial_metagenomes/serc_stuff/fastas/grinder_output_linear_error/reads/all/all.clean.2.fastq
threads = 8

unless File.exist?(in_db_fasta)
  abort("File #{ARGV.first} doesn't exist!\n#{usage}")
end

unless File.exist?(reads_left)
  abort("File #{ARGV.first} doesn't exist!\n#{usage}")
end

unless File.exist?(reads_right)
  abort("File #{ARGV.first} doesn't exist!\n#{usage}")
end

`bwa index -p #{db_prefix} #{in_db_fasta}`

`bwa mem -M -t #{threads} #{db_prefix} #{reads_left} #{reads_right}`
