#!/usr/bin/perl -w
#从stool DNA的.report.tsv文件中提取信息

use strict;
die "perl $0 <report.tsv.list> <stool.report.xls>\n" unless (@ARGV ==2);

open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

print OT "SampleID\tGene\tLocus\tExon\tRef\tAlt\tType\tGenotype\tMAF\tDepth\tConsequence\tDNA_change\tAA_change\tClin_sig\n";
while(<IN>){
	chomp;
	my @tmp=split/\//;
#	my @t=split(/_/,$tmp[-2]);
#	pop @t;
#	shift @t;
	my $sampleID=$tmp[-2];
	open TSV,"$_" or die "Cannot open $_ !\n";
	while(<TSV>){
		chomp;
		if ($_=~/^Chromosome/){next;}
		else {
			my @a=split/\t/;
			if ($a[8]=~/PASS/){
#				$a[0]=~s/chr//;
				my $locus=join ":",$a[0],$a[1];
				if ($a[23]=~/EN.*\(p\.=\)/){$a[23]='(=)';}
				elsif ($a[23]=~/EN.*p\./){$a[23]=~s/EN.*p\.//;}
				$a[12]=~s/\_variant//;
				$a[20]=~s/\/(.+)/\($1\)/;
				$a[22]=~s/EN.+://;
				$a[22]=~s/c\.//;
				$a[23]=~s/p\.//;
#				$a[48]=~s/(.+)(-)//;
				$a[6]=sprintf "%.4f",$a[6];
				my $k=join "\t",$sampleID,$a[14],$locus,$a[20],$a[2],$a[3],$a[4],$a[5],$a[6],$a[7],$a[12],$a[22],$a[23],$a[44];
				print OT "$k\n";
			}
			else {next;}
		}
	}
	close TSV;
}
close IN;
