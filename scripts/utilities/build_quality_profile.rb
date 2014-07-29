#!/usr/bin/env ruby

# build a quality profile from fastq files

require 'parse_fasta'
require 'descriptive_statistics'

Signal.trap("PIPE", "EXIT")

quals = {}
FastqFile.open(ARGV.first, 'r').each_record do |head, seq, desc, qual|
  qual.qual_scores.each_with_index do |q, idx|
    i = idx.to_s.to_sym

    # quals will be { "0" => [23, 34, 43, 43, ...],
    #                 "1" => [3, 23,,12, ...], ... }
    # where each key is a position and the array is all quality values
    # at that position
    if quals.has_key?(i)
      quals[i] << q
    else
      quals[i] = [q]
    end
  end
end

puts "posn,count,mean_qual,sd"
quals.each do |posn, qs|
  puts [posn, qs.count, qs.mean, qs.standard_deviation].join(',')
end
