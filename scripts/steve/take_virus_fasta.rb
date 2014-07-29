#C:\Research\Tools\Ruby200-x64\bin

input_virus = {}

# File.open('C:\Research\Virome\Galaxy\GrinderContigsWithCoverageGTR600', 'r').each_line do |keep|
# 	keeper = keep.scan(/^>\S*/)
# 	lines_to_keep.push = keeper
# end
#fastafiles cuts the > and starts a block for whatever file is the first argument
File.open('C:\Research\Virome\ContigNameWithVVirusName', 'r').each_line do | viruseses |
	#store the header and sequence into a hash
	header, virus_name = viruseses.split(/\t/)
	header = header.match(/^\S*/)[0]
	input_virus[header] = virus_name
end

fileout = File.open('C:\Research\Virome\Galaxy\GrinderVirusCoverageOutput', 'w')
File.open('C:\Research\Virome\Galaxy\GrinderContigsWithCoverageGTR600.tabular', 'r').each_line do |line|
	##### join here is needed to keep this brackets out before turning it into a string
	line = line.chomp
	header = line.scan(/^>\S*/).join.chomp
	header = header.sub(/>/) { '' }
	fileout.write(">#{line}#{input_virus[header]}")
	#print keeper
	#print toout
	#fileout.write("#{toout}")
end
fileout.close

