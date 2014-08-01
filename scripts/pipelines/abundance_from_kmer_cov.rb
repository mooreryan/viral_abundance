#!/usr/bin/env ruby

## reading in the scafSeq file

start_time = Time.now

begin
  require 'trollop'
  require 'parse_fasta'
  require 'shell/executer.rb'
  require 'descriptive_statistics'
rescue LoadError => e
  bad_file = e.message.sub(/^cannot load such file -- /, '')
  abort("ERROR: #{e.message}\nTry running: gem install #{bad_file}")
end

opts = Trollop.options do
  banner <<-EOS

  If the scaf_seq file is `my_file.scafSeq` then the output files will
  be these:

  my_file.n50_table.txt
  my_file.btab
  my_file.abun_from_kmer_cov.txt
  my_file.abun_from_kmer_cov.r
  my_file.n50_table.pdf
  my_file.rank_abundance.pdf


  Options:
  EOS
  opt(:scaf_seq, 'The scafSeq file from SOAPdenovo', type: :string,
      default: '/Users/ryanmoore/sandbox/test.scafSeq')
  opt(:blast, 'Location of your blast binary', type: :string,
      default: '/usr/local/bin/blastn')
  opt(:blast_db, 'Path to blast db', type: :string,
      default: '/Users/ryanmoore/sandbox/blast_dbs/all10.fa')
end

# if opts[:scaf_seq].nil?
#   Trollop.die :scaf_seq, "You must enter a scafSeq file name"
# elsif !File.exist? opts[:scaf_seq]
#   Trollop.die :scaf_seq, "The scafSeq file must exist"
# end

if !File.exist? opts[:scaf_seq]
  Trollop.die :scaf_seq, "The scafSeq file must exist"
end

if !File.exist? opts[:blast_db]
  Trollop.die :blast_db, "The specified file doesn't exist!"
end

def parse_fname(fname)
  { dir: File.dirname(fname), 
    base: File.basename(fname, File.extname(fname)), 
    ext: File.extname(fname) }
end

fname_map = parse_fname(opts[:scaf_seq])

def basic_contig_stats(scaf_seq_file)
  total_bases = 0
  contig_lengths = []
  # records : { contig_name => { length => n, cov => x } }
  records = {}
  FastaFile.open(scaf_seq_file, 'r').each_record do |header, sequence|
    # basic stats
    name, cov = header.split
    name = name
    cov = cov.to_f
    read_len = sequence.length

    # add info to records
    if records.has_key?(name)
      die_string = "Fasta headers aren't unique in #{scaf_seq_file}!" <<
        "\n#{name} is repeated."
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

def write_n50_table(total_bases, contig_lengths)
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

def blast(blast, blast_db, scaf_seq_file, outfile)
  blastn = '/usr/bin/blastn'
  blast_cmd = "#{blast} -db #{blast_db} " << 
    "-query #{scaf_seq_file} -outfmt " <<
    "\"6 qseqid stitle evalue sstart send length bitscore\" >#{outfile}"

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
  blast_out.split("\n").each do |line|
    query, tax_hit, eval, start, stop, length = line.chomp.split("\t")
    
    if hits.has_key?(query) && length > hits[query][:length]
      hits[query] = { query: query, tax_hit: tax_hit, eval: eval, 
        start: start, stop: stop, length: length }
    elsif !hits.has_key?(query)
      hits[query] = { query: query, tax_hit: tax_hit, eval: eval, 
        start: start, stop: stop, length: length }
    end
  end
  hits
end

#### main ####

## step 5: get stats from assembly
t = Time.now
$stderr.print 'Calculating assembly stats...'
records, total_bases, contig_lengths = basic_contig_stats(opts[:scaf_seq])

# write n50 table to disk
n50_f = File.join(fname_map[:dir], "#{fname_map[:base]}.n50_table.txt")
File.open(n50_f, 'w') do |f|
  f.puts %w[level length count].join("\t")
  f.puts write_n50_table(total_bases, contig_lengths)
end
$stderr.puts "Done! (time: #{Time.now - t})"

## step 6: blast the contigs and scaffolds
t = Time.now
$stderr.print 'Blasting sequences...'
outfile = File.join(fname_map[:dir], fname_map[:base] + '.btab')
blast(opts[:blast], opts[:blast_db], opts[:scaf_seq], outfile)
blast_out = File.open(outfile, 'r').read
$stderr.puts "Done! (time: #{Time.now - t})"

## step 7: get the top hit (based on alignment length)
t = Time.now
$stderr.print 'Getting top hits...'
# { query => { :tax_hit, :eval, :start, :stop, :length }
hits = top_hit(blast_out)
$stderr.puts "Done! (time: #{Time.now - t})"

t = Time.now
$stderr.print 'Getting cov stats per tax group...'
tax_cov = {}
hits.values.group_by { |record| record[:tax_hit] }.each do |tax, recs|
  cov_for_this_tax = []
  recs.each do |rec|
    cov_for_this_tax << records[rec[:query]][:cov]
  end
  tax_cov[tax] = { 
    mean_cov: cov_for_this_tax.mean,
    median_cov: cov_for_this_tax.median,
    sd: cov_for_this_tax.standard_deviation,
    count: cov_for_this_tax.count }
end
$stderr.puts "Done! (time: #{Time.now - t})"

t = Time.now
$stderr.print 'Printing tax cov stats data...'
r_data = File.join(fname_map[:dir], 
                   fname_map[:base] + ".abun_from_kmer_cov.txt")
File.open(r_data, 'w') do |f|
  f.puts %w[virus mean.cov median.cov sd count].join("\t")
  tax_cov.each_pair do |tax, info|
    tax_string = tax
      .sub(/^gi.*\| /, '')
      .sub(/, complete.*$/, '')
      .sub(/ genomic sequence$/, '') 
    f.puts [tax_string,
            info[:mean_cov], 
            info[:median_cov], 
            info[:sd], 
            info[:count]].join("\t")
  end
end
$stderr.puts "Done! (time: #{Time.now - t})"



n50_pdf_out = File.join(fname_map[:dir], 
                    fname_map[:base] + ".n50_table.pdf")
rank_pdf_out = File.join(fname_map[:dir], 
                    fname_map[:base] + ".rank_abundance.pdf")

t = Time.now
$stderr.print 'Running R code...'
r_script =
"library('ggplot2')

## n50 graph
pdf(file='#{n50_pdf_out}', width=10, height=7.5)
n50 <- read.table('#{n50_f}', header=T, sep=\"\\t\")

ggplot(n50, aes(x=level, y=length)) +
    geom_bar(position=position_dodge(), 
             stat='identity', fill='dodgerblue2', col='black' ) +
    xlab('X percent of bases contained in contig of length of at least Y') +
    ylab('Contig length') +
    labs(title='Assembly metrics #{opts[:scaf_seq]}') +
    guides(fill=F) +
    theme_bw()
invisible(dev.off())

## rank abundance
pdf(file='#{rank_pdf_out}', width=10, height=7.5)
t <- read.table('#{r_data}', header=T, sep=\"\\t\")
ggplot(t, aes(x=virus, y=mean.cov)) +
    geom_bar(position=position_dodge(), stat='identity', 
             fill='dodgerblue2', col='black') +
    xlab('Virus') +
    ylab('Relative abundance') +
    labs(title='Rank abundance #{opts[:scaf_seq]}') +
    guides(fill=F) +
    theme_bw() +
    theme(axis.text.x = element_text(angle=45, vjust=0.5, size=8))
invisible(dev.off())
"

tmp_r_script = File.join(fname_map[:dir], 
                         fname_map[:base] + ".abun_from_kmer_cov.r")
File.open(tmp_r_script, 'w') do |f|
  f.puts r_script
end

# run the rcode
begin
  Shell.execute!("Rscript #{tmp_r_script}")
rescue RuntimeError => e
  # print stderr if bad exit status
  abort(e.message)
end
$stderr.puts "Done! (time: #{Time.now - t})"

$stderr.puts "All done!!! (total time: #{Time.now - start_time})"
