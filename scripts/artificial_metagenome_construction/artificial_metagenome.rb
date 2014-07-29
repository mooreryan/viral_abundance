#!/usr/bin/env ruby

# written: 02 June 2014, by Ryan Moore

# see ~/tutorials/making_artificial_metagenome.md

require 'parse_fasta'
require 'set'

Signal.trap('PIPE', 'EXIT')

fasta = ARGV[0]
hit_counts = ARGV[1]

def gc(str)
  s = str.downcase
  c = s.count('c')
  g = s.count('g')
  t = s.count('t')
  a = s.count('a')
  u = s.count('u')
  
  return 0 if c + g + t + a + u == 0
  return (c + g).quo(c + g + t + a + u).to_f
end

def rank(vals)
  ranks = []
  rank = 1
  vals.each_with_index do |n, idx|
    if idx.zero?
      ranks << rank
      rank += 1
    else
      if n == vals[idx-1]
        rank -= 1
        ranks << rank
        rank += 1
      else
        ranks << rank
        rank += 1
      end
    end
  end
  ranks
end

# keep this one in memory as it's smaller
hits = {}
abundances = {}
File.open(hit_counts, 'r').each_line do |line|
  name, num_hits, abundance = line.chomp.split(',')

  if hits.has_key?(name)
    abort("ERROR: duplicate name: #{name}")
  else 
    hits[name] = num_hits
    abundances[name] = abundance
  end
end
names = hits.keys

ranks = rank(hits.values)  

puts "rank\thits\tabundance\tgc\tname\theader\tsequence"
File.open(fasta, 'r').each_record do |header, sequence|
  names.each_with_index do |name, idx|
    if header.include?(name)
      puts [ranks[idx], hits[name], abundances[name], gc(sequence), name, 
            header, sequence].join("\t")
    end
  end      
end
