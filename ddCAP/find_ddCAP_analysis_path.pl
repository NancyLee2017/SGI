#!/usr/bin/perl -w
use strict;
#根据libID.list，找出ddCAP样本的分析目录，同时生成report.filtered.tsv.list（不保留空行）
die "perl $0 <libID.list> <target_path> <Output.xls>\n" unless (@ARGV ==3);

open IN,"$ARGV[0]" or die "Open $ARGV[0] error!\n";
open OT,">$ARGV[2]" or die "Create $ARGV[2] error!\n";
open TSV,">$ARGV[2].report.filtered.tsv.list" or die "Create tsv.list error!\n";
my $path=$ARGV[1];
chomp $path;

my @libIDs;
#my %hash;

while(<IN>){
	chomp;
	push @libIDs,$_;
	my $find_name="$_"."*-M";
	my $data_path='not find';
	$data_path=`find $path -name $find_name`;
	if ($data_path=~/\n.+/){$data_path=~s/\n/\t/g;}
	else {chomp $data_path;}
	print OT "$_\t$data_path\n";
	
	my @a=split(/\t|\n/,$data_path);
	my $filename="$_"."*report.filtered.tsv";
	my $tsv=`find $a[0] -name "$filename"`;
	#chomp $tsv;
	if(!($tsv eq /^$/)){print TSV "$_=$tsv";}
	}
close IN;
close OT;
close TSV;

