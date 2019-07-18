#!/usr/bin/perl -w
use strict;

die "perl $0 <report.clinsig.tsv.list> <Combine_tsv.xls>\n" unless (@ARGV ==2);

open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

my @sampleIDs;
print OT "SampleID\tGene\tLocus\tExon\tGenotype\tRef\tAlt\tcDNA_change\tAA_change\tType\tConsequence\tCOSMIC_ID\tClinical_Significant\tFrequency\tDepth\n";
while(<IN>)
{
	chomp;
	my $tsv_path=$_;
	my @temp=split/\//;
	my @t=split(/_/,$temp[-2]);
	my $sampleID="$t[0]"."_"."$t[1]"."="."$tsv_path";
	push @sampleIDs,$sampleID;
	
	open TSV,"$tsv_path" or die "Cannot open $tsv_path !\n";
	while(<TSV>)
	{
		if ($_=~/^Chromosome/){next;}
		else
		{	chomp;
			my @a=split/\t/;
			for(my $i=0;$i<=$#a;$i++){$a[$i]=~s/^\s+//;}
			my $pos=join ":",$a[0],$a[1];
			$pos=~s/chr//;
			my $cosmic;
			if ($a[29]=~/(COSM.+)\&/){$cosmic=$1;}
			else{$cosmic=$a[29];}
			$a[6]=sprintf "%.3f",$a[6];
			$a[48]=~s/[0-9]-//;
			$a[12]=~s/\_variant//;
			$a[20]=~s/\/.+//;
			
			my $k=join "\t",$t[1],$a[14],$pos,$a[20],$a[5],$a[2],$a[3],$a[22],$a[23],$a[4],$a[12],$cosmic,$a[48],$a[6],$a[7];
			print OT "$k\n";
			
		}
		
	}
	close TSV;
}
close IN;
