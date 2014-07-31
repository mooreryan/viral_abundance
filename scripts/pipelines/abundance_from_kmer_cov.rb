#!/usr/bin/env ruby

## reading in the scafSeq file

begin
  require 'trollop'
  require 'parse_fasta'
  require 'shell/executer.rb'
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
  opt(:blast, 'Location of your blast binary', type: :string,
      default: '/usr/local/bin/blastn')
  opt(:blast_db, 'Path to blast db', type: :string,
      default: '/Users/ryanmoore/sandbox/blast_dbs/all10.fa')
end

if opts[:scaf_seq].nil?
  Trollop.die :scaf_seq, "You must enter a scafSeq file name"
elsif !File.exist? opts[:scaf_seq]
  Trollop.die :scaf_seq, "The scafSeq file must exist"
end

if !File.exist? opts[:blast_db]
  Trollop.die :blast_db, "The specified file doesn't exist!"
end

def basic_contig_stats(scaf_seq_file)
  total_bases = 0
  contig_lengths = []
  # records : { contig_name => { length => n, cov => x } }
  records = {}
  die_string = "Fasta headers aren't unique in #{scaf_seq_file}!" <<
    "\n#{name} is repeated."
  FastaFile.open(scaf_seq_file, 'r').each_record do |header, sequence|
    # basic stats
    name, cov = header.split
    name = name.to_sym
    cov = cov.to_f
    read_len = sequence.length

    # add info to records
    if records.has_key?(name)
      abort(die_string)
    else
      records[name] = { length: read_len, cov: cov }
    end

    # for the N50 table
    total_bases += read_len
    contig_lengths << read_len
  end
  [records, total_bases, contig_lengths]
end

def make_n50_table(total_bases, contig_lengths)
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
  n50_table
end

def blast(blast, blast_db, scaf_seq_file)
  blastn = '/usr/bin/blastn'
  blast_cmd = "#{blast} -db #{blast_db}" << 
    "-query #{scaf_seq_file} -outfmt " <<
    "\"6 qseqid stitle evalue sstart send length bitscore\""

  # run command, exit if errors
  begin
    blast_results = Shell.execute!(blast_cmd)
  rescue RuntimeError => e
    # print stderr if bad exit status
    abort(e.message)
  end

  # return std out (blast results)
  blast_results.stdout
end

def top_hit(blast_out)
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
  hits
end

#### main ####

## step 5: get stats from assembly
records, total_bases, contig_lengths = basic_contig_stats(opts[:scaf_seq])
n50_table = make_n50_table(total_bases, contig_lengths)

## step 6: blast the contigs and scaffolds
blast_out = blast(opts[:blast], opts[:blast_db], opts[:scaf_seq])

## step 7: get the top hit (based on alignment length)
hits = top_hit(blast_out)
