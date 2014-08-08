#!/usr/bin/env ruby

# arg1 = base_name
# arg2 = outdir
# infiles are the .abun_from_kmer_cov.txt from the pipeline

require 'descriptive_statistics'

Signal.trap("PIPE", "EXIT")

base = ARGV.shift
outdir = ARGV.shift

outf = File.join(outdir, "#{base}.abun_from_kmer_cov.detailed.txt")
tax_info = {}
File.open(outf, 'w') do |f|
  f.puts %w[virus program kmer mean meadian sd count].join("\t")
  ARGF.each do |line|
    unless line.start_with?("virus\tprogram")
      virus, program, kmer, mean, median, sd, count = line.chomp.split("\t")

      if tax_info.has_key?(virus)
        tax_info[virus] << { virus: virus, program: program, kmer: kmer, 
          mean: mean, median: median, 
          sd: sd, count: count }
      else
        tax_info[virus] = [{ virus: virus, program: program, kmer: kmer, 
                             mean: mean, median: median, 
                             sd: sd, count: count }]
      end

      f.puts [virus, program, kmer, mean, median, sd, count].join("\t")
    end
  end
end

outf = File.join(outdir, "#{base}.abun_from_kmer_cov.averages.txt")
File.open(outf, 'w') do |f|
  # should do the stats on the raw data
  f.puts "tax\tmean.cov\tsd\tmedian.cov\t05\t95\tcount"
  tax_info.sort.each do |tax, info|
    means = info.map { |i| i[:mean].to_i }
    f.puts [tax, means.mean, means.standard_deviation, means.median, 
          means.percentile(5), means.percentile(95), info.count].join("\t")
  end
end
