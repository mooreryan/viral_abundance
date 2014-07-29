#!/usr/bin/env ruby

# updated: 18 June 2014 by Ryan Moore

usage = "USAGE: bowtie2.rb reference_in reads_left reads_right"

if ARGV.count < 3
  abort("ERROR: #{ARGV.count} args given; need 3.\n#{usage}")
end

def parse_fname(fname)
  { dir: File.dirname(fname), 
    base: File.basename(fname, File.extname(fname)), 
    ext: File.extname(fname) }
end

bowtie = '/home/wommacklab/software/bowtie2-2.1.0/bowtie2'
align = '/home/wommacklab/software/bowtie2-2.1.0/bowtie2-align'
index = '/home/wommacklab/software/bowtie2-2.1.0/bowtie2-build'

reference_in = ARGV[0]
reads_left = ARGV[1]
reads_right = ARGV[2]

fname = parse_fname(reference_in)
readsl = parse_fname(reads_left)
readsr = parse_fname(reads_right)

unless File.exist?(reference_in)
  abort("ERROR: #{reference_in} doesn't exist!\n#{usage}")
end

unless File.exist?(reads_left)
  abort("ERROR: #{reads_left} doesn't exist!\n#{usage}")
end

unless File.exist?(reads_right)
  abort("ERROR: #{reads_right} doesn't exist!\n#{usage}")
end


basename = File.join(fname[:dir], fname[:base])

$stderr.puts "INDEXING"
index_output = `#{index} -f #{reference_in} #{basename}`
$stderr.puts index_output

$stderr.puts "BOWTIE-ING"
# OPTION: --omit-sec-sec 
# When printing secondary alignments, Bowtie 2 by default will write
# out the SEQ and QUAL strings. Specifying this option causes Bowtie 2
# to print an asterix in those fields instead. Should make things play
# nice with Picard.
out_sam = "#{File.join(readsl[:dir], fname[:base])}_#{readsl[:base]}_" <<
  "#{readsr[:base]}.sam"
bowtie_cmd = "#{bowtie} --local --very-sensitive-local " << 
  "--omit-sec-seq -x #{basename} -q -1 #{reads_left} " <<
  "-2 #{reads_right} -S #{out_sam}"
bowtie_output = `#{bowtie_cmd}`
$stderr.puts bowtie_output

err_status = $?
if err_status == 0
  $stderr.puts "samfile: #{out_sam}"
else
  warn("Faulty termination! Sam file #{out_sam} may not be written!",
       err_status)
end

