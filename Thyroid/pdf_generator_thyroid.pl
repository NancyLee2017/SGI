#!/usr/bin/perl -w
use strict;
die "perl $0 <tsv.list> <pdf.sh>\n" unless (@ARGV ==2);
open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

my $php='/data/home/jiecui/software/git/ctdna-pipeline/scripts/CreateVariantReport/thyroid_v2/thyroid_v2_report_process.php';

while(<IN>){
	chomp;
	my ($tsv,$fusion,$json,$pdf)=($_,$_,$_,$_);
	my @file=split/\//;
	my $info=$file[-1];
	pop @file;pop @file;
	my $path=join"/",@file;
	$info=~s/\.report\.clinsig\.filtered\.tsv/\.tsv/;$info=$path."/".$info;
	$fusion=~s/\.report\.clinsig\.filtered\.tsv/\.fusion_result\.tsv/;
	$json=~s/\.report\.clinsig\.filtered\.tsv/\.sqm\.json/;
	$pdf=~s/\.report\.clinsig\.filtered\.tsv/\.pdf/;
	print OT "php $php $info $tsv $fusion $json $pdf\n";	
}
