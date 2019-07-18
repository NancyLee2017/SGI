#!/usr/bin/perl -w
#Do matrix for certain mutation site, using "report.tsv" file

use strict;
die "perl $0 <report.tsv.list> <stool.matrix.xls>\n" unless (@ARGV ==2);

open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

my (%hash,%posi);
my @sampleIDs;
my @markers;

open MARK,"/media/raid_disk/home_RAID/hongyanli/script/stool/marker_position.txt" or die "Cannot open marker_position file!\n";
while(<MARK>){
	chomp;
	push @markers,$_;
}close MARK;

while(<IN>){
	chomp;
	my @tmp=split/\//;
#	my @t=split(/_/,$tmp[-2]);
#	pop @t;
#	shift @t;
	my $sampleID=$tmp[-2];
	push @sampleIDs,$sampleID;
	
	open TSV,"$_" or die "Cannot open $_ !\n";
	while(<TSV>){
		chomp;
		if ($_=~/^Chromosome/){next;}
		else {
			my @a=split/\t/;
			my $k=join ":",$a[0],$a[1],$a[2],$a[3];
			$a[6]=sprintf "%.4f",$a[6];
			my $o=$a[6];
#			if ($a[8]=~/PASS/){
#				$o=$a[6]."|".$a[7];}
#			else{$o=$a[6]."|".$a[8];}
			$hash{$sampleID}{$k}=$o;
		}
	}
	close TSV;
}
close IN;

my @sampleID_sort=sort @sampleIDs;
print OT "\t";
for(my $i=0;$i<=$#markers;$i++){print OT "$markers[$i]\t";}
print OT "\n";
for(my $i=0;$i<=$#sampleID_sort;$i++){
	print OT "$sampleID_sort[$i]\t";
	for(my $j=0;$j<=$#markers;$j++){
		if(exists $hash{$sampleID_sort[$i]}{$markers[$j]}){print OT "$hash{$sampleID_sort[$i]}{$markers[$j]}\t";}
		else{print OT "0\t";}
	}
	print OT "\n";
}close OT;

