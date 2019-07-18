#!/usr/bin/perl -w
use strict;

#输入文件为libID.list
die "perl $0 <libID.list> <gz_path> <ReadsCount.xls>\n" unless (@ARGV ==3);

open IN,"$ARGV[0]" or die "Open $ARGV[0] error!\n";
open OT,">$ARGV[2]" or die "Create $ARGV[2] error!\n";

my $path=$ARGV[1];
chomp $path;

my @libIDs;
#my %hash;

while(<IN>){
	chomp;
	push @libIDs,$_;
	my $gz_name="$_"."*_R1*.gz";
	my $gz_path='NA';
	$gz_path=`find $path -name $gz_name`;
	chomp $gz_path;
#	$hash{$_}=$gz_path;
	my $lines=0;
	$lines=`zcat $gz_path |wc -l`; 
	if ($lines!=0){chomp $lines;}
	my $reads_num=0;
	$reads_num=($lines/4);
	print OT "$_\t$gz_path\t$reads_num\n";
	}
close IN;
close OT;

#open IN2,"path.list" or die "Open path.list error!\n";
#open OT,">$ARGV[2]" or die "Create $ARGV[2] error!\n";
#while (<IN2>){
#	chomp;
#	for (my $i=0;$i<=$#libIDs;$i++){
#		if ($_=~$hash{$libIDs[$i]}){print OT "$libIDs[$i]\t$_\n";}
#	}
#}
#close IN2;
#close OT;
#system("rm path.list");