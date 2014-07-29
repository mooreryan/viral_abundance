#!/usr/bin/env ruby

# written: 4 June 2014 Ryan Moore

# split Grinder pared end fasta files, they dont have their own
# description and the header is really weird so for the description
# line ive made it mirror the refseq fasta header

def parse_fname(fname)
  { dir: File.dirname(fname), 
    base: File.basename(fname, File.extname(fname)), 
    ext: File.extname(fname) }
end

fname = parse_fname(ARGV.first)
f1 = File.open(File.join(fname[:dir], "#{fname[:base]}.1.fastq"), 'w')
f2 = File.open(File.join(fname[:dir], "#{fname[:base]}.2.fastq"), 'w')

count = 0
flag = nil
desc = ''
File.open(ARGV.first, 'r').each_line do |line|
  line.chomp!

  case count % 4
  when 0
    header = line
    ref = line.split('=')[1].sub(/ position$/, ' ')
    name = line.split('=').last.gsub(/"/, '')
    desc = ref << name

    which_pair = line.split(' ').first[-1]
    if which_pair == '1'
      flag = 'first'
      f1.puts header
    elsif which_pair == '2'
      flag = 'second'
      f2.puts header
    end
  when 1
    sequence = line
    if flag == 'first'
      f1.puts sequence
    elsif flag == 'second'
      f2.puts sequence
    end
  when 2
    description = line
    if flag == 'first'
      f1.puts description << desc
    elsif flag == 'second'
      f2.puts description << desc
    end
  when 3
    quality = line
    if flag == 'first'
      f1.puts quality
    elsif flag == 'second'
      f2.puts quality
    end
  end
  count += 1
end
