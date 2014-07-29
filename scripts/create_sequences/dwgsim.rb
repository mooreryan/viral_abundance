#!/usr/bin/env ruby

usage = "USAGE: dwgsim.rb in.ref.fa num_read_pairs"

if ARGV.count < 2
  abort(usage)
end

unless File.exist?(ARGV.first)
  abort("File #{ARGV.first} doesn't exist!\n#{usage}")
end

def parse_fname(fname)
  { dir: File.dirname(fname), 
    base: File.basename(fname, File.extname(fname)), 
    ext: File.extname(fname) }
end

in_ref_fa = ARGV[0]
fname = parse_fname(in_ref_fa)
out_prefix = File.join(fname[:dir], fname[:base])
dwgsim = '/usr/local/dwgsim_0.1.11/dwgsim'
err_rate = 0.006
inner_dist = 100
# sd = 10 # this parameter breaks things when passed
num_read_pairs = ARGV[1]
# mean_cov = -1 # disable
read_len = 250
reads_for = 0 # illumina

cmd = "#{dwgsim} -e #{err_rate} -E #{err_rate} -d #{inner_dist} " <<
  "-N #{num_read_pairs} -1 #{read_len} " <<
  "-2 #{read_len} -c #{reads_for} #{in_ref_fa} #{out_prefix}"

`time #{cmd}`
