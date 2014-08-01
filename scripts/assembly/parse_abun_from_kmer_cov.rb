#!/usr/bin/env ruby

require 'descriptive_statistics'

Signal.trap("PIPE", "EXIT")

tax_info = {}
ARGF.each do |line|
  unless line.start_with?("virus\tmean.cov")
    virus, mean, median, sd, count = line.chomp.split("\t")

    if tax_info.has_key?(virus)
      tax_info[virus] << { virus: virus, mean: mean, median: median, 
                           sd: sd, count: count }
    else
      tax_info[virus] = [{ virus: virus, mean: mean, median: median, 
                           sd: sd, count: count }]
    end
  end
end

# should do the stats on the raw data
puts "tax\tmean.cov\tsd\tmedian.cov\t05\t95"
tax_info.sort.each do |tax, info|
  means = info.map { |i| i[:mean].to_i }
  puts [tax, means.mean, means.standard_deviation, means.median, 
        means.percentile(5), means.percentile(95)].join("\t")
end

  
