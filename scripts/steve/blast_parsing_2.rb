#C:\research\C:\Research\Tools\Ruby200-x64\bin

infile = 'C:\Research\Virome\BLASTdb\SimSeqBlastOutput.txt'
BestSeq = ["qseqid", "stitle", "evalue", "sstart", "send", "length", "bitscore"]
File.open(infile, 'r').each do |line|
	qseqid, stitle, evalue, sstart, send, length, bitscore = line.split(/\t/)
	if BestSeq.include?(qseqid) == false
		BestSeq.push(qseqid, stitle, evalue, sstart, send, length, bitscore)
	elsif
		BestSeq[-7] == qseqid && BestSeq[-2] <= length
		BestSeq.slice!(-7,7)
		BestSeq.push(qseqid, stitle, evalue, sstart, send, length, bitscore)
	end
end
#print BestSeq

File.open('C:\Research\Virome\SimSeqRubyOutBestUnFilteredContigs', 'w'){|file| BestSeq.each_slice(7) {|x| file.puts x.join("	")}}


