#!/usr/bin/perl -w

use strict;
die "Usage: perl $0 <sqm.json.list> <qc.out.xls>\n" unless (@ARGV ==2);
open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";
#/OncoAim_denovo/new_report/CLS_171008_miseq_PE150_20171009/GHY-FF171002002-D01-L01-M_S6/GHY-FF171002002-D01-L01-M_S6.sqm.json
my %qc;
print OT "SampleID\tTotal_read\tMapped_read\tMapped_rate\tOntarget_read\tOntarget_rate\tAverage_amplicon_coverage\tUniformity\n";
while(<IN>){
	chomp;
	my @a=split/\//;
	my $sampleID=$a[-2];
	open JSON,"$_" or die "Cannot open $_ !\n";
	while(<JSON>){
		$_=~s/\"//g;
		$_=~s/\}//g;
		my @b=split/,/;
		for (my $i=0;$i<=$#b;$i++){$b[$i]=~s/.+:\s//;}
		my $map_rate=$b[5]/$b[3];
		$map_rate=sprintf "%.3f",$map_rate;
		my $tar_rate=$b[0]/$b[5];
		$tar_rate=sprintf "%.3f",$tar_rate;
		my $k=join "\t",$b[3],$b[5],$map_rate,$b[0],$tar_rate,$b[1],$b[2];
		$qc{$sampleID}=$k;
		print OT "$sampleID\t$k\n";
	}
}