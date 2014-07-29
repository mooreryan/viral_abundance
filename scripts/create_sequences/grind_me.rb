#!/usr/bin/env ruby

ref_file = ARGV[0]
num_reads = ARGV[1]
ext = ref_file.split('.').pop
base_name = File.basename(ref_file, ext)

script = '/home/wommacklab/software/Grinder-0.5.0/bin/grinder'
outdir = '/home/moorer/projects/artificial_metagenomes/serc_stuff/' <<
  'fastas/grinder_output_linear_error'
profile = '/home/moorer/scripts/grinder/grinder_settings.txt'

cmd = "#{script} -reference_file #{ref_file} -total_reads #{num_reads}" <<
  " -base_name #{base_name} -output_dir #{outdir}" <<
  " -profile_file #{profile}"

`#{cmd}`
  

