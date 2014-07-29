#!/usr/bin/env ruby

usage <<-EOS
  USAGE: dwgsim_wrapper.rb arg_file

  The arg_file lists the paths, files and number of reads you want for
  each file. Note that the number is the number of *reads* not the
  number of *fragments*.

  example arg_file:

    path=/home/mooorer/my_files
    file_1.fa,5000
    file_2.fa,4208
    another.fa,99898
EOS

fnames = {}
path = ''
File.open(ARGV.first, 'r').each_line do |line|
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

fnames.each do |fname, num|
  num -= 1 unless num.even?
  `/home/moorer/scripts/dwgsim.rb #{fname} #{num.to_i/2}`
end



#!/usr/bin/env ruby

fnames = {}
File.open(ARGV.first, 'r').each_line do |line|
  fname, num = line.chomp.split(',')
  
  fnames[fname] = num
end

fnames.each do |fname, num|
  `/home/moorer/scripts/dwgsim.rb #{fname} #{num.to_i/2}`
end
