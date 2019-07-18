#!/usr/bin/perl -w
use strict;

die "perl $0 <bam.list> <local.path>\n" unless (@ARGV ==2);

open IN,"$ARGV[0]" or die "$ARGV[0] ERROR!\n";
my $bam_path="$ARGV[1]"."\\";
my $igv_path="$ARGV[1]"."\\IGV\\";
my $num=0;

while (<IN>){
	chomp;
	$num++;
	print "#$num\nnew\n";
	print "load \"$bam_path";
	if (/^IonXpress_(\d+)_rawlib\.bam/){print "$_\"\n";}
	elsif(/^IonXpress_/){print "$_"."_rawlib\.bam\"\n";}
	else{ print STDOUT "ERROR:Not PGM normal format bam!\n";}
	print "snapshotDirectory \"$igv_path";
	print "$_\\\"\n";
	print "goto chr2:234668873-234668913\nsort position\ncollapse\nsnapshot\n";
}
