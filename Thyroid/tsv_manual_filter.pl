#!/usr/bin/perl -w
use strict;
die "perl $0 <tsv.list> <remove_site.list>\n" unless (@ARGV ==2);
open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open IN2,"$ARGV[1]" or die "$ARGV[1] Error!\n";

my %fp;
while(<IN2>){
	chomp;
	$fp{$_}=1;
}close IN2;

while(<IN>){
	chomp;
	my ($tsv,$tsv_ori,$tsv_filt);
	$tsv=$_;
	$tsv_filt=$_."filtered";
	$tsv_ori=$_.".ori";

	my $cmd=`cp $tsv $tsv_ori`;if($cmd){print "$cmd\ncopy $tsv successfully!\n"}
	open TSV,"$tsv" or die "ERROR: Can't open $tsv \n";
	open OT,">$tsv_filt" or die "ERROR: Can't creat $tsv_filt\n";
	while(<TSV>){
		if(/Chromosome/){print OT "$_";next;}
		my @t=split/\t/;
		my $site=$t[0].":".$t[1]."\t".$t[2]."\t".$t[3];
		if (exists $fp{$site}){
			print "$tsv delete $site\n";
		}
		else {print OT "$_";}
	}close TSV;
	`rm $tsv`;
	`mv $tsv_filt $tsv`;
}close IN;




open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

