#!/usr/bin/perl -w
use strict;

#输入文件为tab分隔的两列，第一列为libID，第二列为PGM index编号
die "perl $0 <input.list> <bam_path> <Samplesheet.txt>\n" unless (@ARGV ==3);

open IN,"$ARGV[0]" or die "Open $ARGV[0] error!\n";
open OT,">$ARGV[2]" or die "Create $ARGV[2] error!\n";

my $path=$ARGV[1];
#my $out=$ARGV[2];
my @libIDs;
my %hash;

chomp $path;
#chomp $out;
while(<IN>){
	chomp;
	my @a=split/\t/;
	my $libID=$a[0];
	push @libIDs,$libID;
	my $index=$a[1];
	$hash{$libID}=$index;
	my $bam_name="$index"."*bam";
	system("find $path -name $bam_name >>path.list");
	}
close IN;

open IN2,"path.list" or die "Open path.list error!\n";
while (<IN2>){
	chomp;
	for (my $i=0;$i<=$#libIDs;$i++){
		if ($_=~$hash{$libIDs[$i]}){print OT "$libIDs[$i]\t$_\n";}
	}
}
close IN2;
close OT;
system("rm path.list");