#!/usr/bin/env ruby

require 'set'

ref = ARGV[1]
bam = ARGV[0]

`samtools view -o #{ref}.sam #{bam} #{ref}`

references_a = `cut -f3 #{ref}.sam | sort -u`
references_b = `cut -f7 #{ref}.sam | sort -u`

refset = Set.new
refs = references_a << references_b

refs.split("\n").each { |r| refset << r unless r == "=" }

sam = bam.sub(/sorted\.bam/, 'sam')

reff = 'refs.89797541231316549679875431.txt'

File.open(reff, 'w') do |f|
  f.puts "^@HD"
  refset.each { |r| f.puts "^@.*#{r}" }
end

refhf = 'refs_headers.5465132164987654321.txt'

`grep -f #{reff} #{sam} > #{refhf}`

tmp = 'tmp.87654132131313132165467498743'
`cat #{refhf} #{ref}.sam > #{tmp}`
`mv #{tmp} #{ref}.sam`

`rm #{refhf} #{reff}`

o = `/home/moorer/public/artificial_metagenomes/scripts/utilities/samtools.sh #{ref}.sam`

puts o

