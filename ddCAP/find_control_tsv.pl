#!/usr/bin/perl -w

#通过libID匹配，找特定样本的TSV

use strict;

die "perl $0 <controlID.list> <all_tsv.list> <out>\n" unless (@ARGV ==3);

open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT,">$ARGV[2]" or die "Error! Cannot open $ARGV[2] \n";

while(<IN>){
	chomp;
	my $qc_id=$_;
	open IN2, "$ARGV[1]" or die "Error! Cannot open $ARGV[1]\n";
	while (<IN2>){
		chomp;
		my $id=(split/=/)[0];
		if ($qc_id eq $id){print OT "$_\n"}
		else {next;}
	}	
	close IN2;
}
close IN;
close OT;
