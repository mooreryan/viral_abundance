#!/usr/bin/env ruby

# written: 03 June 2014, by Ryan Moore

# see ~/tutorials/making_artificial_metagenome.md

Signal.trap('PIPE', 'EXIT')

hits = {}
File.open(ARGV.first, 'r').each_line do |line|
  name, abundance = line.chomp.split(',')    

  if hits.has_key?(name)
    abort("ERROR: duplicate name: #{name}")
  else 
    hits[name] = abundance.to_i
  end
end

total_hits = hits.values.reduce(:+).to_f

hits.each do |name, hits|
  puts [name, hits, hits/total_hits].join(',')
end
