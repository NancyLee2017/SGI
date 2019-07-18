#!/usr/bin/perl -w
use strict;

#输入QC样本的libID
die "perl $0 <in ID.list> <out report.filtered.tsv.list> \n" unless (@ARGV ==2);
open IN, "$ARGV[0]" or die "Open $ARGV[0] error!\n";
open OT, ">$ARGV[1]" or die"Creat out file error!\n";
while(<IN>){
    chomp;
    my @a=split/-/;
    pop @a; pop @a;
    my $sampleID=join "-",@a;
    my $find_name=$sampleID."*report.filtered.tsv";
    my @tsv=`find /data/home/hongyanli/workspace/ -name $find_name |grep -v Download`;
    foreach my $k (@tsv) {
        my $libID=(split/\//,$k)[-2];
        print OT "$libID=$k"};
}

