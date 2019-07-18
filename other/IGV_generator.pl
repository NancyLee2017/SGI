#!/usr/bin/perl -w
use strict;

die "perl $0 <bam.list> <local.path>\n" unless (@ARGV ==2);

open IN,"$ARGV[0]" or die "$ARGV[0] ERROR!\n";
my $bam_path="$ARGV[1]"."\\bam\\";
my $igv_path="$ARGV[1]"."\\IGV\\";
my $num=0;

while (<IN>){
chomp;
$num++;
print "#$num\nnew\n";
print "load \"$bam_path";
print "$_"."\.clean.bam\"\n";
print "snapshotDirectory \"$igv_path";
print "$_\\\"\n";
print "goto chr4:55561744-55561830\nsort position\ncollapse\nsnapshot\n";
print "goto chr4:55592063-55592155\nsort position\ncollapse\nsnapshot\n";
print "goto chr4:55593598-55593692\nsort position\ncollapse\nsnapshot\n";
print "goto chr4:55594157-55594243\nsort position\ncollapse\nsnapshot\n";
print "goto chr4:55595494-55595565\nsort position\ncollapse\nsnapshot\n";
print "goto chr4:55599293-55599382\nsort position\ncollapse\nsnapshot\n";
print "goto chr4:55602627-55602717\nsort position\ncollapse\nsnapshot\n";
print "goto chr4:55602758-55602846\nsort position\ncollapse\nsnapshot\n";
print "goto chr7:55210028-55210118\nsort position\ncollapse\nsnapshot\n";
print "goto chr7:55211040-55211128\nsort position\ncollapse\nsnapshot\n";
print "goto chr7:55220152-55220242\nsort position\ncollapse\nsnapshot\n";
print "goto chr7:55221820-55221914\nsort position\ncollapse\nsnapshot\n";
print "goto chr7:55227932-55228020\nsort position\ncollapse\nsnapshot\n";
print "goto chr7:55229173-55229263\nsort position\ncollapse\nsnapshot\n";
print "goto chr7:55231364-55231446\nsort position\ncollapse\nsnapshot\n";
print "goto chr7:55232965-55233055\nsort position\ncollapse\nsnapshot\n";
print "goto chr7:55241646-55241730\nsort position\ncollapse\nsnapshot\n";
print "goto chr7:55242412-55242501\nsort position\ncollapse\nsnapshot\n";
print "goto chr7:55249004-55249103\nsort position\ncollapse\nsnapshot\n";
print "goto chr7:55259481-55259565\nsort position\ncollapse\nsnapshot\n";
print "goto chr7:55260409-55260496\nsort position\ncollapse\nsnapshot\n";
print "goto chr7:55273544-55273632\nsort position\ncollapse\nsnapshot\n";
}
