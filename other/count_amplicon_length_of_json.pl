#!/usr/bin/perl -w
use strict;

die "perl $0 <json_file> <out.xls>\n" unless (@ARGV ==2);

open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT,">$ARGV[1]" or die "Open $ARGV[1] error!\n";

while(<IN>){
    chomp;
    s/"//g;
    my @temp=split/, /;
#    print "$temp[0]\n";
    for (my $i=0;$i<=$#temp;$i++){
        if (/chr/){
	    my @a=split/:/,$temp[$i];
	    my $region=$a[1];
	    my @b=split/-/,$region;
	    my $length=$b[1]-$b[0];
	    my $out="$a[0]".":"."$a[1]"."\t"."$length";
	    print OT "$out\n";
	}
    }
}
close IN;
close OT;
