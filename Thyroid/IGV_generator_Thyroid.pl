#!/usr/bin/perl -w 
use strict;

die "perl $0 <id.list> <local_path_date> <target_site.list> <igv.batch>\n" unless (@ARGV==4);

open IN,"$ARGV[0]" or die "Cannot open list $ARGV[0] \n";
open OT,">$ARGV[3]" or die "Cannot creat batch file $ARGV[3] \n";

my $bam_path="$ARGV[1]"."\\bam\\";
#print "$bam_path\n";
my $igv_path="$ARGV[1]"."\\IGV\\ \n";
#my $num=0;

while(<IN>){
	chomp;
	my $bam=$bam_path.$_.".bw_dedup.bam";#print "$bam\n";
	print OT "#$_\nnew\n";
	print OT "load $bam\n";
	print OT "snapshotDirectory $igv_path";
	open IN2,"$ARGV[2]" or die "Cannot open target_site $ARGV[2]\n";
	while(<IN2>){
		chomp;
		my @a=split;
		print OT "#$a[0]\n";
		my $start;my $end;my $region;
		until ($a[3]<$a[2]){
			$start=$a[1].$a[2];
			$a[2]=$a[2]+5000;
			$end="-".$a[2]; 
			$region=$start.$end;
			print OT "goto $region\nsort position\ncollapse\nsnapshot\n";
		}
#		$end="-".$a[3];$region=$start.$end;print "goto $region\nsort position\ncollapse\nsnapshot\n";
#		print OT "goto $_\nsort position\ncollapse\nsnapshot\n";
	}close IN2;
	print OT "\n";
}
close IN;

