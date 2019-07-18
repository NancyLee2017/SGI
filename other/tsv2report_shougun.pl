#!/usr/bin/perl -w
#统计每个sample，每个位点的信息（包括该位点的depth）
use strict;

die "perl $0 <tsv.list> <Combine_tsv.xls>\n" unless (@ARGV ==2);

open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

#my @sampleID;
print OT "SampleID\tGene\tLocus\tLocation\tExon\tIntron\tGenotype\tRef\tAlt\tType\tcodon_change\tAA_change\tDepth\tMAF\tClinical_Significant\n";
while(<IN>)
{
	chomp;
	my @tmp=split/\//;
#	my @t=split(/_/,$tmp[-2]);
#	pop @t;
#	my $sampleID=join "_",@t;
	my $sampleID=$tmp[-2];
	open TSV,"$_" or die "Cannot open $_ !\n";
	while(<TSV>)
	{
		next if($_=~/^Chromosome/);
		my @a=split/\t/;
#		for(my $i=0;$i<=$#a;$i++){$a[$i]=~s/^\s+//;}
		if($a[8]=~/PASS/){
			my $pos=join ":",$a[0],$a[1];
			if ($a[23]=~/EN.*\(p\.=\)/){$a[23]='(=)';}
			elsif ($a[23]=~/EN.*p\./){$a[23]=~s/EN.*p\.//;}
			$a[22]=~s/EN.+://;
			my $k=join "\t",$sampleID,$a[14],$pos,$a[19],$a[20],$a[21],$a[5],$a[2],$a[3],$a[4],$a[22],$a[23],$a[7],$a[6],$a[44];
			print OT "$k\n";
		}
	}
	close TSV;
}
close IN;
