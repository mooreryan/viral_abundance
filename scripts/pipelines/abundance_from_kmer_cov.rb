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

  If the scaf_seq file is `test_127.scafSeq` then the output files will
  be these:

  test_127.abun_from_kmer_cov.r
  test_127.abun_from_kmer_cov.txt
  test_127.btab
  test_127.contigs_kept.txt
  test_127.contigs_rejected.txt
  test_127.n50_table.pdf
  test_127.n50_table.txt
  test_127.rank_abundance.pdf
  test_127.reference_coverage.txt

  Now the scafSeq file must be in the format
  ginder_program_kmerSize.scafSeq, in order to populate the kmer size
  and the grinder program columns in the abun_from_kmer_cov.txt
  file. Might die if the format is incorrect.

  Options:
  EOS
  opt(:references, 'The fasta file of reference sequences',
      type: :string, default: '/Users/ryanmoore/projects/steve/viral_abundance/test_files/inputs/all_10.fa')
  opt(:scaf_seq, 'The scafSeq file from SOAPdenovo', type: :string,
      default: '/Users/ryanmoore/projects/steve/viral_abundance/test_files/inputs/test_127.scafSeq')
  opt(:blast, 'Location of your blast binary', type: :string,
      default: '/usr/local/bin/blastn')
  opt(:blast_db, 'Path to blast db', type: :string,
      default: '/Users/ryanmoore/projects/steve/viral_abundance/test_files/blast_db/all10.fa')
  opt(:outdir, 'Output directory', type: :string,
      default: '/Users/ryanmoore/projects/steve/viral_abundance/test_files/output')
  opt(:reduce_coverage, 'Flag true to run coverage reduction algorithm',
      type: :boolean, default: true)
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

if opts[:outdir].nil?
  Trollop.die :outdir, "You must enter a folder name"
elsif !File.exist? opts[:outdir]
  Trollop.die :outdir, "The file must exist"
end


def parse_fname(fname)
  { dir: File.dirname(fname), 
    base: File.basename(fname, File.extname(fname)), 
    ext: File.extname(fname) }
end

fname_map = parse_fname(opts[:scaf_seq])
# will grab kmer size if the scaf_seq file name is of the form
# simseq_119.scafSeq where 119 is the kmer size
begin
  the_match = opts[:scaf_seq].match(/.*\/(.*)_(\d+)\.scafSeq/)
  grinder_program = the_match[1]
  kmer_size = the_match[2]
rescue NoMethodError => e
  $stderr.puts e.message
  abort("Improrper file name format for #{opts[:scaf_seq]}")
end

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
    "\"6 qseqid stitle evalue sstart send length bitscore\" " <<
    ">#{outfile} -evalue 100 -penalty -2 -reward 2 -gapopen 0 " <<
    "-gapextend 4"

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
n50_f = File.join(opts[:outdir], "#{fname_map[:base]}.n50_table.txt")
File.open(n50_f, 'w') do |f|
  f.puts %w[level length count].join("\t")
  f.puts write_n50_table(total_bases, contig_lengths)
end
$stderr.puts "Done! (time: #{Time.now - t})"

## step 6: blast the contigs and scaffolds
t = Time.now
$stderr.print 'Blasting sequences...'
outfile = File.join(opts[:outdir], fname_map[:base] + '.btab')
blast(opts[:blast], opts[:blast_db], opts[:scaf_seq], outfile)
blast_out = File.open(outfile, 'r').read
$stderr.puts "Done! (time: #{Time.now - t})"

## step 7: get the top hit (based on alignment length)
t = Time.now
$stderr.print 'Getting top hits...'
# each value is basically a top hit from the btab file.
# { query => { :query, :tax_hit, :eval, :start, :stop, :length } }
hits = top_hit(blast_out)
$stderr.puts "Done! (time: #{Time.now - t})"

def percent_covered(array)
  (array.count - array.count(0)) / array.count.to_f
end

# TODO get reference lengths here
# { reference_name => length }
ref_lengths = {}
FastaFile.open(opts[:references], 'r').each_record do |header, sequence|
  if ref_lengths.has_key?(header)
    abort("ERROR: #{header} isn't uniuqe in #{opts[:references]}")
  else
    ref_lengths[header] = sequence.length
  end
end

def clean_tax_string(tax_str)
  tax_str
    .sub(/^gi.*\| /, '')
    .sub(/, complete.*$/, '')
    .sub(/ genomic sequence$/, '')
end

cov_file = File.join(opts[:outdir], 
                     "#{fname_map[:base]}.reference_coverage.txt")
kept_file = File.join(opts[:outdir], 
                      "#{fname_map[:base]}.contigs_kept.txt")
rejected_file = 
  File.join(opts[:outdir], 
            "#{fname_map[:base]}.contigs_rejected.txt")
cov_f = File.open(cov_file, 'w')
kept_f = File.open(kept_file, 'w')
rejected_f = File.open(rejected_file, 'w')
cov_f.puts "name\tbase\tcov"

if opts[:reduce_coverage]
  begin
    ## step 7.5 'coverage reduction' algorithm
    hits.values.group_by { |record| record[:tax_hit] }
      .each do |tax, recs|
      tax_string = clean_tax_string(tax)
      # fill array with zeros for length of reference sequence
      ref_coverage = Array.new(ref_lengths[tax], 0)

      # make reference sequence coverage data structure
      # tax is the value of tax_hit from hits
      # recs are all the top hits to this tax group
      sorted_records = recs.sort_by { |record| record[:length] }
      sorted_records.each do |record|
        if percent_covered(ref_coverage) > 0.90
          break
        else
          start = record[:start].to_i
          stop = record[:stop].to_i
          start, stop = stop, start if stop < start

          # slice the region
          region = (start..stop)
          cov_of_region_on_ref = ref_coverage[region]
          if percent_covered(cov_of_region_on_ref) < 0.5
            # add a good flag to hits
            hits[record[:query]][:keep] = true

            # add 1 to the coverage at the proper positions
            region.each do |posn|
              ref_coverage[posn] += 1
            end
          else
            hits[record[:query]][:keep] = false
          end
        end
      end
      ref_coverage.each_with_index do |cov, idx|
        base = idx + 1
        cov_f.puts [tax_string, base, cov].join("\t")
      end
    end
    # hits will now be
    # { query => { :query, :tax_hit, :eval, :start, :stop, :length } }
    kept = hits.values.select { |hit| hit[:keep] }
    rejected = hits.values.reject { |hit| hit[:keep] }
    kept.each do |info|
      info.each_pair do |k, v|
        kept_f.puts "#{k}\t#{v}"
      end
    end
    rejected.each do |info|
      info.each_pair do |k, v|
        rejected_f.puts "#{k}\t#{v}"
      end
    end
    # hits now only contains the ones flagged with keep
    hits = kept
  ensure
    cov_f.close
    kept_f.close
    rejected_f.close
  end
end

## stats per tax group
t = Time.now
$stderr.print 'Getting cov stats per tax group...'
tax_cov = {}
hits.group_by { |record| record[:tax_hit] }.each do |tax, recs|
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
r_data = File.join(opts[:outdir], 
                   fname_map[:base] + ".abun_from_kmer_cov.txt")
File.open(r_data, 'w') do |f|
  f.puts(%w[virus program kmer.size mean.cov median.cov sd count]
           .join("\t"))
  tax_cov.each_pair do |tax, info|
    tax_string = clean_tax_string(tax)
    f.puts [tax_string,
            grinder_program,
            kmer_size,
            info[:mean_cov], 
            info[:median_cov], 
            info[:sd], 
            info[:count]].join("\t")
  end
end
$stderr.puts "Done! (time: #{Time.now - t})"



n50_pdf_out = File.join(opts[:outdir], 
                    fname_map[:base] + ".n50_table.pdf")
rank_pdf_out = File.join(opts[:outdir], 
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

tmp_r_script = File.join(opts[:outdir], 
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
