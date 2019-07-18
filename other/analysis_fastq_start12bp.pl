#! /usr/bin/perl -w
use strict;

die "#usage:perl $0 <fastq.gz> <out.stat>\n" unless @ARGV==2;

my $fa=$ARGV[0];
my (%hash_h,%hash_t);
open OT1,">$ARGV[1].head24bp.xls" or die "$ARGV[1].head24bp.xls error!\n";
#open OT2,">$ARGV[1].tail28bp.xls" or die "$ARGV[1].tail28bp.xls error!\n";

if($fa=~/\.gz/){open IN,"gzip -cd $fa|" or die "$fa error!\n";} 
else {open IN,"$fa" or die "$fa error!\n";}
while(<IN>){
	chomp;
	my $title=$_;
	my $seq=<IN>;
	my $t=<IN>;
	my $qc=<IN>;
	chomp($seq);
	my $subseq_h=substr($seq,0,24);
#	my $subseq_t=substr($seq,120,28);
	$hash_h{$subseq_h}+=1;
#	$hash_t{$subseq_t}+=1;
}close IN; 

foreach my $k(keys %hash_h){
	print OT1 "$k\t$hash_h{$k}\n";
}close OT1;
#foreach my $k(keys %hash_t){
#        print OT2 "$k\t$hash_t{$k}\n";
#}close OT2;
