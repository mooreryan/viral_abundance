#!/usr/bin/env ruby

# written: 02 June 2014, by Ryan Moore

# see ~/tutorials/making_artificial_metagenome.md

# parses the output from virome and counts the number of hits per
# species

require 'set'

Signal.trap('PIPE', 'EXIT')

species_counts = {}
File.open(ARGV.first, 'r').each_line do |line|
  unless line.start_with?('"Blast') || line.start_with?('Blast')
    species = line.chomp.split(',').last.gsub(/"/, '').gsub(/,/, '_')
    
    if species_counts.has_key?(species)
      species_counts[species] += 1
    else
      species_counts[species] = 1
    end
  end
end

species_counts.sort_by { |_, n| n }.reverse.each do |species, count|
  puts [species, count].join(',')
end
