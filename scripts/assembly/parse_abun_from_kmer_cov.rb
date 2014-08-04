#!/usr/bin/env ruby

# infiles are the .abun_from_kmer_cov.txt from the pipeline

require 'descriptive_statistics'

Signal.trap("PIPE", "EXIT")

tax_info = {}
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
  end
end

# should do the stats on the raw data
puts "tax\tmean.cov\tsd\tmedian.cov\t05\t95\tcount"
tax_info.sort.each do |tax, info|
  means = info.map { |i| i[:mean].to_i }
  puts [tax, means.mean, means.standard_deviation, means.median, 
        means.percentile(5), means.percentile(95), info.count].join("\t")
end
