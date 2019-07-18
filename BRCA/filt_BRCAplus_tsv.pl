#!/usr/bin/perl -w
use strict;
die "perl $0 <report.tsv.list> <target.site.list> <generate_BRCAplus_newreport.sh>\n" unless (@ARGV ==3);

open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open LIST, "$ARGV[1]" or die "Error! Cannot open $ARGV[1]\n";
open OT,">$ARGV[2]" or die "Error! Cannot open $ARGV[2]\n";

my $php='/BRCAim_Luigi/bin.brcaim/ctdna-pipeline/scripts/CreateVariantReport/new_brcaim_v3/brcaim_tsv_analysis.php';
my %hash_target;

while(<LIST>){
	chomp;
	my @a=split/\:|\t/;
	my $k=join ":",$a[0],$a[1],$a[2],$a[3];
	$hash_target{$k}+=1;
#	print "$k\n";
}

while(<IN>){
	chomp;
	my ($raw_tsv,$new_tsv,$new_pdf,$json,$new_clin_tsv)=($_,$_,$_,$_,$_);
	$new_tsv=~s/report.tsv/report.new.tsv/;
	$new_pdf=~s/report.tsv/report-tsv.new.pdf/;
	$json=~s/report.tsv/sqm.json/;
	$new_clin_tsv=~s/report.tsv/report.clinsig.new.tsv/;
	my $ori="$_".".ori";
	if(-e $ori){print "$ori exist!\n"}
	else{system("cp $_  $ori");}
	my @t=split/\//;
	my $tsv_name=pop @t;
	my $ID=(split/_/,$tsv_name)[1];
#	my $workpath=join "/" @t;

	open TSV,"$_" or die "Error:Cannot open tsv file!\n";
	open TSV2,">$new_tsv" or die "Error:Cannot creat new tsv file!\n";
	while(<TSV>){
		chomp;
		if(/^Chromosome/){print TSV2 "$_\n";}
		else{
			my @t=split/\t/;
			my $pos =join ":",$t[0],$t[1];
			my $key=join ":",$t[0],$t[1],$t[2],$t[3];
			if (exists $hash_target{$key}){
				if($t[8]=~/PASS/){print TSV2 "$_\n";}
				elsif($t[8]=~/^Blacklisted/)
				{
					print "Change $ID mutation $pos from $t[8] to PASS !\n";
					$t[8]='PASS';
					my $line=join"\t",@t;
					print TSV2 "$line\n";
				}
			}
			else{next;}
		}
	}
	close TSV2; close TSV;
	
	system("rm $raw_tsv");
	system ("mv $new_tsv $raw_tsv");	
	print OT "php $php $raw_tsv sgi $new_pdf $json seqstore_ffpe_cn $new_clin_tsv \n";
	
}
