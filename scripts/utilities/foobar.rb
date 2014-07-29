#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

btab = ARGV[0]
# stats = ARGV[1]

# File.open(stats, 'r').each_line do |line|
  
# end

# { query: { gi: gi_number, e_val: e_value }
top_hits = {}
File.open(btab, 'r').each_line do |line|
  line_a = line.chomp.split("\t")
  query, gi, this_e_val = line_a[0].to_sym, line_a[1], line_a[10].to_f
  
  if top_hits.has_key?(query) && this_e_val < top_hits[query][:e_val]
    top_hits[query] = { gi: gi, e_val: this_e_val }
  elsif !top_hits.has_key?(query)
    top_hits[query] = { gi: gi, e_val: this_e_val }
  end
end

top_hits.each { |k, v| puts [k, v[:gi]].join("\t") }
