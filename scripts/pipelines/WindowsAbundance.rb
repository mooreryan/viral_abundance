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

scaf_seq = opts[:scaf_seq]

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

FastaFile.open(scaf_seq, 'r').each_record do |header, sequence|
  # basic stats
  name, cov = header.split
  name = name.to_sym
  cov = cov.to_f
  
  die_string = "Fasta headers aren't unique in #{scaf_seq}!\n#{name}" <<
  " is repeated."

  if records.has_key?(name)
    abort(die_string)
  else
    records[name.to_s] = { length: sequence.length, cov: cov }
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

puts "_____________________"
puts "       N table       "
puts "_____________________\n\n"
puts n50_table
## blast the contigs and scaffolds
# blastn = '/usr/bin/blastn'
# blast_cmd = "#{blastn} -db /home/moorer/public/artificial_" << 
#   "metagenomes/blast_dbs/all10.fa -query #{scaf_seq} outfmt \"6 " <<
#   "qseqid stitle evalue sstart send length bitscore\""
blastn = 'C:\Program Files\NCBI\blast\bin\blastn.exe'
######## TODO ########
#the blast algorithm is cutting off some good contigs, lightening the
#stringency might help.  has been edited, just keep testing this one
blast_cmd = "\"#{blastn}\" -db C:\\Research\\Virome\\BLASTdb\\all10.fa -query #{scaf_seq} -outfmt \"6 " <<
  "qseqid stitle evalue sstart send length bitscore\" -evalue 100 -penalty -2 -reward 2 -gapopen 0 -gapextend 4"

blast_out = check_status(blast_cmd).split("\n")
#DELETE THIS LINE, though it does show that blast is missing some good shit
## get the top hit (based on alignment length)
hits = {}
blast_out.each do |line|
  contig, phage, eval, start, stop, length = line.chomp.split("\t")
  contig = contig.to_s
  # if length.to_i > 1000
  #   puts line
  # end
  if hits.has_key?(contig)
    if length.to_i >= hits[contig][:length].to_i
      #puts "#{hits[contig][:length]}  wrote over with this one  #{length}"
      hits[contig] = { phage: phage, eval: eval, start: start, 
                     stop: stop, length: length }
    end          
  else
    hits[contig] = { phage: phage, eval: "original", start: start, 
                     stop: stop, length: length }
  end
end
 
# create an array that lists viruses to be covered
# and gives there length in an hash with ref name
refs = {}
ref_file = "C:\\Research\\Virome\\BLASTdb\\all10.fa"
FastaFile.open(ref_file, 'r').each_record do |ref_name, ref_seq|
  ref_length = ref_seq.length
  refs[ref_name] = ref_length.to_i
end
#  Creates an empty coverage matrix for each reference
ref_matrix = {}
refs.each do |phage, length|
  # it might be better to do the math later and insert true here
  # if using true, then the array could be more organized
  ref_matrix[phage] = Array.new(length, 0)
end
# A hash that will house covered genomes for output
ref_covered = {}
########  Test Genome Stats ########
hits.each do |reference_check|
  ######## outputs from reference_check ########
  # a 2 component array with 0 as contig name and 1 as hash with:
  # ["scaffold1", {:phage=>"gi|526244935|ref|NC_021864.1| Puniceispirillum phage HMO-2011, complete genome", :eval=>"0.0", :start=>"11
  # 41", :stop=>"11521", :length=>"381"}]
  # gives contig name
  contig = reference_check[0].chomp
  # copies array from reference_check
  contig_stats = reference_check[1]
  #  assigns the phage to work with
  ref_phage = contig_stats[:phage].to_s
  # checks the table to see if the phage is covered yet, only happens from giant contigs, so far
  if ref_covered.has_key?(ref_phage) == false
    # makes sure that your reference has a hit
    if refs.has_key?(ref_phage)
      # takes your reference and gets the length for reference
      ref_length = refs[ref_phage].to_i
      # make some values to use for coverage check
      start = contig_stats[:start].to_i
      stop = contig_stats[:stop].to_i
      length = contig_stats[:length].to_i
      coverage = records[contig][:cov].to_i
      #  check to see if the length of the contig is close to genome length already
      if length >= ref_length * 0.90 && length <= ref_length * 1.10
        # stores the contig name and coverage into ref_covered with the status of covered
        # this hash contains covered genomes only
        ref_covered[ref_phage] = { covered: true, status: "covered", contigs: contig, coverage: coverage }
      #checks to see if the contig is too long
      elsif length >= ref_length * 1.10
        coverage = records[contig[:cov]].to_i
        # puts genome into ref_covered with warning that contig is oversized
        ref_covered[ref_phage] = { covered: false, status: "oversized contig", contigs: contig, coverage: coverage }
      elsif ref_matrix[ref_phage][start] == 0 && ref_matrix[ref_phage][stop] == 0
        # Adds start and stop into the matrix and fills in the missing parts
        # the lengths should be sorted before doing this
        if start > stop
          ref_matrix[ref_phage][stop]..ref_matrix[ref_phage][start] = coverage
        else
          ref_matrix[ref_phage][start]..ref_matrix[ref_phage][stop] = coverage
        end
        # matrix coverage check and math for coverage go here
      end
    end
  else
    #puts "Duplicate #{ref_phage}    #{contig}      #{contig_stats[:length].to_i}     #{start}      #{stop}"
  end
end
puts "_____________________"
puts "   Covered Genomes   "
puts "_____________________\n\n"
ref_covered.each do |covered_out|
  puts covered_out
end