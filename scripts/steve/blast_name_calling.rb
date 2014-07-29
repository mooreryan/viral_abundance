#C:\Research\Tools\Ruby200-x64\bin

fileout = File.open('C:\Research\Virome\SimSeqContigNameWithVirusName', 'w')

File.open('C:\Research\Virome\SimSeqRubyOutBestUnFilteredContigs', 'r' ).each_line do |line|
	contig, name, evalue, length, bitscore = line.split(/\t/)
	short_name = name.match(/\s.*$/)
	fileout.write("#{contig}\t#{short_name}\n")
end
