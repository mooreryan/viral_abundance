#!/usr/bin/env ruby

# written: 03 June 2014, by Ryan Moore

# see ~/tutorials/making_artificial_metagenome.md

require 'set'

Signal.trap('PIPE', 'EXIT')

grep_list = ARGV[0]
art_metag_f = ARGV[1]

names = Set.new
File.open(grep_list, 'r').each_line do |line|
  names << line.chomp
end

File.open(art_metag_f, 'r').each_line do |line|
  rank, hits, abundance, gc, name, header, sequence = line.chomp.split("\t")

  fname = name.gsub(/[ :]/, '_')
  
  names.each do |n|
    if n == name
      f = File.open("#{fname}.fa", 'w')
      f.puts ">#{header}\n#{sequence}" 
      f.close
      break
    end
  end
end
