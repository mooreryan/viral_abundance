#!/usr/bin/env ruby

## reading in the scafSeq file

begin
  require 'trollop'
  require 'parse_fasta'
rescue LoadError => e
  bad_file = e.message.sub(/^cannot load such file -- /, '')
  abort("ERROR: #{e.message}\nTry running: gem install #{bad_file}")
end

opts = Trollop.options do
  banner <<-EOS

  This is our fun script!

  Options:
  EOS
  opt :scaf_seq, 'The scafSeq file from SOAPdenovo', type: :string
end

if opts[:scaf_seq].nil?
  Trollop.die :scaf_seq, "You must enter a scafSeq file name"
elsif !File.exist? opts[:scaf_seq]
  Trollop.die :scaf_seq, "The scafSeq file must exist"
end

# catches unix errors (not ruby errors). dies if exit status other
# than 0, else return std. out
def check_status cmd
  output = `#{cmd}`
  if $?.success?
    output
  else
    err_string = "\nERROR!!!\nWhile running: #{cmd}\nPID: #{$?.pid}\n" <<
      "Exit status: #{$?.exitstatus}\nOutput: #{output}"
    abort(err_string)
  end
end

total_bases = 0
contig_lengths = []
# records : { contig_name => { length => n, cov => x } }
records = {}
die_string = "Fasta headers aren't unique in #{scaf_seq}!\n#{name}" <<
  " is repeated."
FastaFile.open(scaf_seq, 'r').each_record do |header, sequence|
  # basic stats
  name, cov = header.split
  name = name.to_sym
  cov = cov.to_f
  
  if records.has_key?(name)
    abort(die_string)
  else
    records[name] = { length: sequence.length, cov: cov }
  end

  # for the N50 table
  read_len = sequence.length
  total_bases += read_len
  contig_lengths << read_len
end

# write the N50 table
n50_table = []
n50_array = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
n50_array.each_with_index do |num, outer_idx|
  n_stat = total_bases * num
  sum = 0
  contig_lengths.sort.reverse.each_with_index do |len, inner_idx|
    sum += len
    if sum > n_stat
      n50_table << ["N#{outer_idx+1}0", len, inner_idx+1].join("\t")
      break
    end
  end
end

## blast the contigs and scaffolds
blastn = '/usr/bin/blastn'
blast_cmd = "#{blastn} -db /home/moorer/public/artificial_" << 
  "metagenomes/blast_dbs/all10.fa -query #{scaf_seq} outfmt \"6 " <<
  "qseqid stitle evalue sstart send length bitscore\""

blast_out = check_status(blast_cmd).split("\n")

## get the top hit (based on alignment length)
hits = {}
blast_out.each do |line|
  contig, phage, eval, start, stop, length = line.chomp.split("\t")
  
  if hits.has_key?(contig) && length > hits[contig][:length]
    hits[contig] = { phage: phage, eval: eval, start: start, 
                     stop: stop, length: length }
  else
    hits[contig] = { phage: phage, eval: eval, start: start, 
                     stop: stop, length: length }
  end
end

  
  
  
