#!/usr/bin/perl -w

# MANUAL FOR metagenemark2fasta.pl

=pod

=head1 NAME

metagenemark2fasta.pl -- Converts MetaGeneMark gff output to FASTA

=head1 SYNOPSIS

 metagenemark2fasta.pl --in /path/to/infile.gff
                     [--help] [--manual]

=head1 DESCRIPTION

 Converts a MetaGeneMark GFF file from GFF format to
 FASTA format. Will fail unless the GFF contains from AA and NT.
 
=head1 OPTIONS

=over 3

=item B<-i, --in>=FILENAME

Input file in GFF format. (Required) 

=item B<-h, --help>

Displays the usage message.  (Optional) 

=item B<-m, --manual>

Displays full manual.  (Optional) 

=back

=head1 DEPENDENCIES

Requires the following Perl libraries.


=head1 AUTHOR

Written by Daniel Nasko, 
Center for Bioinformatics and Computational Biology, University of Delaware.

=head1 REPORTING BUGS

Report bugs to dnasko@udel.edu

=head1 COPYRIGHT

Copyright 2013 Daniel Nasko.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.  
This is free software: you are free to change and redistribute it.  
There is NO WARRANTY, to the extent permitted by law.  

Please acknowledge author and affiliation in published work arising from this script's 
usage <http://bioinformatics.udel.edu/Core/Acknowledge>.

=cut


use strict;
use Getopt::Long;
use File::Basename;
use Pod::Usage;

#ARGUMENTS WITH NO DEFAULT
my($infile,$help,$manual);
my $outdir = "./";

GetOptions (
    "i|in=s"=>\$infile,
    "o|out=s" => \$outdir,
    "h|help"=>\$help,
    "m|manual"=>\$manual);

# VALIDATE ARGS
pod2usage(-verbose => 2)  if ($manual);
pod2usage( {-exitval => 0, -verbose => 2, -output => \*STDERR} )  if ($help);
pod2usage( -msg  => "\n\n ERROR!  Required argument --infile not found.\n\n", -exitval => 2, -verbose => 1)  if (! $infile );

my $aa_out = $infile;
my $nt_out = $infile;

$aa_out =~ s/\.gz$//;
$nt_out =~ s/\.gz$//;
$aa_out =~ s/\.gff.*$/.orf.aa.fasta/;
$nt_out =~ s/\.gff.*$/.orf.nt.fasta/;

$aa_out = $outdir . $aa_out;
$nt_out = $outdir . $nt_out;

my ($header,$start,$stop);
my $dna_flag = 0;
my $pro_flag = 0;
my $protein_holder = '';
my $geneId;
my %Header;
my %Sequence;

open(OUTA,">$aa_out") || die "\n\n Fatal: Cannot open the AA out file: $aa_out\n\n";
open(OUTN,">$nt_out") || die "\n\n Fatal: Cannot open the NT out file: $nt_out\n\n";
if ($infile =~ m/\.gz$/) {
    open(IN,"gunzip -c $infile |") || die "\n\n Fatal: Cannot open the input file: $infile\n\n";
    while(<IN>) {
        chomp;
        if ($_ !~ m/^#/ && $_ !~ m/^$/) {
            my @A = split(/\t/, $_);
            $header = $A[0];
	    $header =~ s/ .*//;
            if ($A[6] eq "+") {
		$start = $A[3];
                $stop = $A[4];
            }
	    elsif ($A[6] eq "-") {
                $start = $A[4];
                $stop = $A[3];
            }
	    else {
                die "\n\n Fatal: Cannot tell if this is in sense or antisense orientation\n$_\n";
            }
            if (exists $Header{$header}) {
		my $string = $header . "_" . $start . "_" . $stop . "_" . $Header{$header} ;
                my $gene_id = $A[8];
                $gene_id =~ s/.* //;
                $Sequence{$gene_id} = $string;
		$Header{$header}++
            }
	    else {
                my $string = $header . "_" . $start . "_" . $stop . "_1" ;
		my $gene_id = $A[8];
		$gene_id =~ s/.* //;
		$Sequence{$gene_id} = $string;
		$Header{$header} = 2;
            }
	}
	elsif ($_ =~ m/^##Protein/) {
            $geneId = $_;
            $geneId =~s/.* //;
            print OUTA ">" . $Sequence{$geneId} . "\n";
            $pro_flag =1;
        }
        elsif ($_ =~ m/##end-Protein/) {
	    my $header = $Sequence{$geneId};
	    $header =~ s/_\d+$//;
	    my $stop = $header;
	    my $start = $header;
	    $stop =~ s/.*_//;
	    $start =~ s/_\d+$//;
	    $start =~ s/.*_//;
	    my $length = $stop - $start;
	    if ($length < 0) { $length *= -1;}
	    $length++;
	    $length /=3;
	    if ($length == length($protein_holder)) {
		print OUTA "$protein_holder\n";
	    }
	    elsif ($length-1 == length($protein_holder)) {
		$protein_holder = $protein_holder . "*";
		print OUTA "$protein_holder\n";
	    }
	    else {
		die "\n\nError: The function that determines if a stop codon is present has failed . . .\n\n";
	    }
            $pro_flag =0;
	    $protein_holder = '';
	}
        elsif ($pro_flag == 1) {
            my $line = $_;
            $line =~ s/^##//;
	    $protein_holder = $protein_holder . "$line";
        }
	elsif ($_ =~ m/^##DNA/) {
            my $gene_id = $_;
            $gene_id =~s/.* //;
            print OUTN ">" . $Sequence{$gene_id} . "\n";
            $dna_flag =1;
        }
        elsif ($_ =~ m/##end-DNA/) {
            $dna_flag =0;
	}
        elsif ($dna_flag == 1) {
            my $line = $_;
            $line =~ s/^##//;
		print OUTN "$line\n";
	}
    }
    close(IN);
}
else {
    open(IN,"<$infile") || die "\n\n Fatal: Cannot open the input file: $infile\n\n";
	while(<IN>) {
	    chomp;
	    if ($_ !~ m/^#/ && $_ !~ m/^$/) {
		my @A = split(/\t/, $_);
		$header = $A[0];
		if ($A[6] eq "+") {
		    $start = $A[3];
		    $stop = $A[4];
		}
		elsif ($A[6] eq "-") {
		    $start = $A[4];
		    $stop = $A[3];
		}
		else {
		    die "\n\n Fatal: Cannot tell if this is in sense or antisense orientation\n$_\n";
		}
		if (exists $Header{$header}) {
		    my $string = $header . "_" . $start . "_" . $stop . "_" . $Header{$header} ;
		    my $gene_id = $A[8];
		    $gene_id =~ s/.* //;
		    $Sequence{$gene_id} = $string;
		    $Header{$header}++
		}
		else {
		    my $string = $header . "_" . $start . "_" . $stop . "_1" ;
		    my $gene_id = $A[8];
		    $gene_id =~ s/.* //;
		    $Sequence{$gene_id} = $string;
		    $Header{$header} = 2;
		}
	    }
	    elsif ($_ =~ m/^##Protein/) {
		   $geneId = $_;
		   $geneId =~s/.* //;
		   print OUTA ">" . $Sequence{$geneId} . "\n";
		   $pro_flag =1;
		}
        elsif ($_ =~ m/##end-Protein/) {
	       my $header = $Sequence{$geneId};
	       $header =~ s/_\d+$//;
	       my $stop = $header;
	       my $start = $header;
	       $stop =~ s/.*_//;
	       $start =~ s/_\d+$//;
	       $start =~ s/.*_//;
	       my $length = $stop - $start;
	       if ($length < 0) { $length *= -1;}
	       $length++;
	       $length /=3;
	       if ($length == length($protein_holder)) {
		   print OUTA "$protein_holder\n";
	       }
	       elsif ($length-1 == length($protein_holder)) {
		   $protein_holder = $protein_holder . "*";
		   print OUTA "$protein_holder\n";
	       }
	       else {
		   die "\n\nError: The function that determines if a stop codon is present has failed . . .\n\n";
	       }
	       $pro_flag =0;
	       $protein_holder = '';
	    }
	    elsif ($pro_flag == 1) {
		my $line = $_;
            $line =~ s/^##//;
		$protein_holder = $protein_holder . "$line";
	    }
	    elsif ($_ =~ m/^##DNA/) {
		   my $gene_id = $_;
		   $gene_id =~s/.* //;
		   print OUTN ">" . $Sequence{$gene_id} . "\n";
		   $dna_flag =1;
		}
        elsif ($_ =~ m/##end-DNA/) {
	       $dna_flag =0;
	    }
	    elsif ($dna_flag == 1) {
		my $line = $_;
            $line =~ s/^##//;
		print OUTN "$line\n";
	    }
	}
	close(IN);
}
close(OUTA);
close(OUTN);
