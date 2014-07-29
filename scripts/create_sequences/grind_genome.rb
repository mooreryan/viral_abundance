#!/usr/bin/env ruby

usage <<-EOS
  USAGE: grind_genome.rb arg_file program

  program is is one of two options:
    grinder
    dwgsim

  The arg_file lists the paths, files and number of reads you want for
  each file. Note that the number is the number of *reads* not the
  number of *fragments*.

  example arg_file:

    path=/home/mooorer/my_files
    file_1.fa,5000
    file_2.fa,4208
    another.fa,99898
EOS

arg_file, program = ARGV
program.downcase!.gsub!(/['"]/, '')

unless arg_file.exist?(arg_file)
  abort("File #{arg_file} doesn't exist!\n#{usage}")
end

unless program == 'grinder' || program == 'dwgsim'
  abort("program must be either 'grinder' or 'dwgsim'\n #{usage}")
end

fnames = {}
path = ''
File.open(fname, 'r').each_line do |line|
  line.chomp!
  if line.start_with?('path=')
    path = line.sub(/^path=/, '')
    unless File.exist?(path)
      abort("Directory #{path} doesn't exist!\n#{usage}")
    end
  else
    fname, num = line.chomp.split(',')
  
    fnames[File.join(path, fname)] = num
  end
end

if program = 'grinder'
  script = 'grinder.rb'
  adjustment = 1 # grinder counts reads
else
  script = 'dwgsim.rb'
  adjustment = 2 # dwgsim counts read pairs
end

fnames.each do |fname, num|
  num -= 1 unless num.even?
  `time #{script} #{fname} #{num.to_i/adjustment}`
end
