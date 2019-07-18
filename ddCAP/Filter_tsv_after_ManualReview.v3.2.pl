#!/usr/bin/perl -w
use strict;
die "perl $0 <in.all.tsv.list> <need_to_remove.pos.list> <client,eg: sgi> <out.generate_pdf.sh> <server:e.g:CLS1 or Mars> <10gene_id.list>\n" unless (@ARGV ==6);
open LST,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open POS,"$ARGV[1]" or die "$ARGV[1] Error!\n";
open OTS,">$ARGV[3]" or die "$ARGV[3] Error!\n";
my $generate_pdf;
if($ARGV[4]=~/Mars/i){$generate_pdf="/home/jiecui/software/git/ctdna-pipeline/scripts/CreateVariantReport/new_oncoaim/oncoaim_tsv_analysis.php";}
elsif($ARGV[4]=~/CLS1/i){$generate_pdf="/data/home/tinayuan/Software/GitLab/ctdna-pipeline/scripts/CreateVariantReport/new_oncoaim/oncoaim_tsv_analysis.php";}
else{$generate_pdf="/data/home/jiecui/software/git/ctdna-pipeline/scripts/CreateVariantReport/new_oncoaim/oncoaim_tsv_analysis.php";}

my %hash;
while(<POS>){
	chomp;
	my @a=split/\:|\t/;
	$a[2]=~s/^\s+//;$a[3]=~s/^\s+//;
	my $k=join "\t",$a[0],$a[1],$a[2],$a[3];
	$hash{$k}=1;
}close POS; 

my %hash_id;
open ID,"$ARGV[5]" or die "$ARGV[5] Error!\n";
while(<ID>){
	chomp;
	$hash_id{$_}=1;
}close ID;

while(<LST>){
	chomp;
	my @f=split/\=/;
	`cp $f[1] $f[1].ori`;
	my @runfolder=split/\//,$f[1];pop @runfolder;
	my $runpath=(join "/",@runfolder);
	open TSV,"$f[1].ori" or die "$f[1].ori error!\n";
	open OT,">$f[1]" or die "$f[1] error!\n";
	while(<TSV>){
		chomp;
		my @a=split/\t/;
		my $k=join "\t",$a[0],$a[1],$a[2],$a[3];
		if(($_=~/\tPASS\t/) && (exists $hash{$k})){
			$_=~s/\tPASS\t/\tManual_Review_Filter\t/;
			print OT "$_\n";
		}else{print OT "$_\n";}
	}close TSV;close OT;
	my ($pdf,$json,$protsv,$fusion1,$fusion2,$cnv)=($f[1],$f[1],$f[1],$f[1],$f[1],$f[1]);
	my ($template,$fusion);
#	$pdf=~s/\.report.filtered.tsv/\_report.$ARGV[3].pdf/;
	$json=~s/\.report.filtered.tsv/\.sqm.json/;
	$protsv=~s/\.report.filtered.tsv/\.processed.tsv/;
	$fusion1=~s/\.report.filtered.tsv/\.fusion_result.tsv/;
	$fusion2=$runpath."/fusion_result.tsv";
	$cnv=~s/\.report.filtered.tsv/\.cnv.tsv/;
	my $clininfo_tsv=join ".",$f[0],"tsv";
	if($f[1]=~/cHOPE(\_?)v1/i){$template="chope_v1_CN";}
	elsif($f[1]=~/cHOPE(\_?)v2/i){$template="chope_v2_CN";}
	elsif($f[1]=~/ddCAPonTissu/i){
		$template="oncoaim_lung_CN";
		if($f[0]=~/AKM/){
			$template="akm_oncoaim_lung_CN";
		}
		if(exists $hash_id{$f[0]}){$template="oncoaim_lung_CN10";}
		$fusion=$fusion1;
	}
	elsif($f[1]=~/ddCAP(\_?)v2/i || $f[1]=~/ddCAP(\_?)ctDNA/i){
		$template="plasaim_lung_CN";
		if($f[0]=~/AKM/){
			$template="akm_plasaim_lung_CN";
		} 
		if(exists $hash_id{$f[0]}){$template="plasaim_lung_CN10";}
		$fusion=$fusion2;
	}
	
	elsif($f[1]=~/OncoAim/i){$template="oncoaim_CN";}
	else{print "No template\n";}
	$pdf=~s/\.report.filtered.tsv/\.report.$template.pdf/;
	if(-e $cnv){
		print OTS "php $generate_pdf $f[1] $ARGV[2] $pdf $json $template $protsv $clininfo_tsv $fusion $cnv\n";}
	else{
		print OTS "php $generate_pdf $f[1] $ARGV[2] $pdf $json $template $protsv $clininfo_tsv\n";
	}
}close LST;
close OTS;
