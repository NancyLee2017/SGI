#!/usr/bin/perl -w
#统计每个sample，filter pass位点的信息(适用于OncoAim luigi运行结果)
use strict;

die "perl $0 <tsv.list> <Combine_tsv.xls>\n" unless (@ARGV ==2);

open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

#my @sampleID;
print OT "SampleID\tGene\tLocus\tExon\tGenotype\tRef\tAlt\tAA_change\tType\tConsequence\tClinical_Significant\tMAF\tAve_cover_depth\n";
while(<IN>)
#/home/hongyanli/workspace/OncoAim_manual/0730_miseq_PE150/CMU-FR170725020-D01-L01-M/CMU-FR170725020-D01-L01-M.report.tsv
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
		if ($_=~/^Chromosome/){next;}
		else
		{
			my @a=split/\t/;
			for(my $i=0;$i<=$#a;$i++){$a[$i]=~s/^\s+//;}
			if ($a[23]=~/EN.*\(p\.=\)/){$a[23]='(=)';}
			elsif ($a[23]=~/EN.*p\./){$a[23]=~s/EN.*p\.//;}
			my $pos=join ":",$a[0],$a[1];
			if ($a[8]=~/PASS/){
				my $k=join "\t",$sampleID,$a[14],$pos,$a[20],$a[5],$a[2],$a[3],$a[23],$a[4],$a[12],$a[44],$a[6],$a[7];
				print OT "$k\n";
			}
		}
		
	}
	close TSV;
}
close IN;
