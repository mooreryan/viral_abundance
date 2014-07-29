#!/usr/bin/env ruby

usage = "USAGE: soapdenovo.rb configuration.config out_prefix"

if ARGV.count < 2
  abort(usage)
end

config = ARGV[0]
output = ARGV[1]
kmer = ARGV[2]
threads = 5

unless File.exist?(config)
  abort("File #{ARGV.first} doesn't exist!\n#{usage}")
end

`/usr/local/bin/SOAPdenovo-127mer all -s #{config} -o #{output}_#{kmer} -p #{threads} -K #{kmer}`
