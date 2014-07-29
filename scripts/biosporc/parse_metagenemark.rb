#!/usr/bin/env ruby

Signal.trap('PIPE', 'EXIT')

File.open(ARGV.first, 'r').each_line do |line|
  line.chomp!
  if line.start_with?('>')
    line.sub!(/^>/, '')
    ref = line.split(' ').first
    start, stop, num = line.match(/\d+_\d+_\d+$/).to_s.split('_')

    coordinates = [start, stop].map { |s| s.to_i }.sort
    puts [ref, "orf#{num}", coordinates].flatten.join(',')
  end
end
