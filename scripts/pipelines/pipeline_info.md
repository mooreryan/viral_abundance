## Kmer cov abundance of mock community ##

1. Make mock community

2. Grind reads

3. Assemble reads

4. Gap closure

5. Get some stats from assembly
   - Info we need from scafSeq file:
	 - lengths of contigs and scaffolds
	 - coverage (from headers)
	 - total num contigs and scaffolds
	 - N10 to N90 graphs
	 - best assembly is the one with the fewest contigs but also the
       longest? (maybe something like n70 / number contigs)

6. Blast contigs and scaffolds against references

7. Get the 'top hits' to assign taxonomy
   - What is the best way to get top hits?
   - might not matter much cos if a short contig is mis-assigned,
     well, short ones will likely be thrown out anyway

(here) Perhaps we should chuck out contigs or scaffolds that differ
widly in coverage from other contigs or scaffolds that have the same
taxonomic hit

8. Select minimum number of contigs to cover the referece
   - preferentially select the longest contigs you can
   - this sorta assumes that all the contigs and scaffolds for one
     reference should have similar kmer coverage

These contigs and scaffolds that are left are the dataset we work
with.

9. Get coverage stats for each taxonomic set
   - mean
   - median
   - sum

10. Use the cov stat to build rank abundance curve
