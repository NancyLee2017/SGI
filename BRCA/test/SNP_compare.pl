#!/usr/bin/perl -w

use strict;

die "perl $0 <report.tsv.list> <SNP.xls> <cutoff eg:0.05>\n" unless (@ARGV ==3); 

open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT, ">$ARGV[1]" or die "Error! Cannot open $ARGV[1]\n";

my (%hash, %posi);
my @samples;

while (<IN>){
    chomp;
    my @tem=split/\//;
    my $libID=(split/_/,$tem[-1])[1];
    push @samples, $libID;
    open TSV, "$_" or die "Error! Cannot open tsv file: $_ \n";
    while(<TSV>){
	chomp;
        my @a=split/\t/;
        if ($a[6]<$ARGV[2]){next;}
        else{
            my $k=join"\t",$a[0],$a[1],$a[2],$a[3];
            $a[6]=sprintf "%.4f",$a[6];
            $hash{$libID}{$k}=$a[6]."|".$a[7];
            $posi{$k}=1;
        }
    }
}close IN;

print OT "Chr\tPos\tRef\tAlt\t";
for (my $i=0;$i<=$#samples;$i++){print OT "$samples[$i]\t";}
print OT "\n";
foreach my $k(sort keys %posi){
    print OT "$k\t";
    for (my $i=0;$i<=$#samples;$i++){
        print OT "$hash{$samples[$i]}{$k}\t";
    }print OT "\n";
}
close OT;
