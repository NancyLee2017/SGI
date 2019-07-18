#!/usr/bin/perl -w
use strict;
die "perl $0 <report.extra.clinsig.tsv.list> <remove_site.list> <generate_oncoDNA_newreport.sh>\n" unless (@ARGV ==3);

open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open LIST, "$ARGV[1]" or die "Error! Cannot open $ARGV[1]\n";
open OT,">$ARGV[2]" or die "Error! Cannot open $ARGV[2]\n";

my $php='/BRCAim_Luigi/bin.brcaim/ctdna-pipeline/scripts/CreateVariantReport/new_oncoaim/oncoaim_tsv_analysis.php';
my %hash_remove;

while(<LIST>){
	chomp;
	my @a=split/\:|\t/;
	my $k=join ":",$a[0],$a[1],$a[2],$a[3];
	$hash_remove{$k}+=1;
#	print "$k\n";
}

while(<IN>){
	chomp;
	my ($raw_tsv,$new_tsv,$new_pdf,$json,$new_clin_tsv)=($_,$_,$_,$_,$_);
	$raw_tsv=~s/report.extra.clinsig.tsv/report.extra.tsv/;
	$new_tsv=~s/report.extra.clinsig.tsv/report.extra.new.tsv/;
	$new_pdf=~s/report.extra.clinsig.tsv/new.pdf/;
	$json=~s/report.extra.clinsig.tsv/sqm.json/;
	$new_clin_tsv=~s/report.extra.clinsig.tsv/report.extra.clinsig.new.tsv/;
#	my $ori="$raw_tsv".".ori";
#	if(-e $ori){print "$ori exist!\n"}
#	else{system("cp $raw_tsv  $ori");}
	my @t=split(/\//, $raw_tsv);
	my $tsv_name=pop @t;
	my $ID=(split/_/,$tsv_name)[0];
#	my $workpath=join "/" @t;

	open TSV,"$raw_tsv" or die "Error:Cannot open tsv file!\n";
	open TSV2,">$new_tsv" or die "Error:Cannot creat new tsv file!\n";
	while(<TSV>){
		chomp;
		if(/^Chromosome/){print TSV2 "$_\n";}
		else{
			my @t=split/\t/;
#			my $pos =join ":",$t[0],$t[1];
			my $key=join ":",$t[0],$t[1],$t[2],$t[3];
			if (exists $hash_remove{$key}){
#				if($t[8]=~/PASS/){print TSV2 "$_\n";}
#				elsif($t[8]=~/^Blacklisted/)
#				{
					print "Remove $key mutation from $ID !\n";
					$t[8]='Manually_removed';
					my $line=join"\t",@t;
					print TSV2 "$line\n";
#				}
			}
			else{print TSV2 "$_\n";}
		}
	}
	close TSV2; close TSV;
	
#	system("rm $raw_tsv");
#	system ("mv $new_tsv $raw_tsv");	
	print OT "php $php $new_tsv sgi $new_pdf $json new_oncoaim_runon_fancy_condensed_CN $new_clin_tsv \n";
	
}
