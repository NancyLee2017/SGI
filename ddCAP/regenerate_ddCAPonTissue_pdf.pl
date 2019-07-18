#!/usr/bin/perl -w
use strict;

#根据sumup表中的分析结果路径，重新给样本生成报告
die "perl $0 <path.list> <redo_report.sh> <CLS|AKM>\n"  unless (@ARGV ==3);
open IN, "$ARGV[0]" or die "$ARGV[0] ERROR!\n";
open OT, ">$ARGV[1]" or die "$ARGV[1] ERROR!\n";

my $php='/data/home/tinayuan/Software/GitLab/ctdna-pipeline/scripts/CreateVariantReport/new_oncoaim/oncoaim_tsv_analysis.php';
my $template;
if ($ARGV[2]=~/AKM|akm/){$template='akm_oncoaim_lung_CN';}
elsif ($ARGV[2]=~/CLS|cls/){$template='oncoaim_lung_CN';}

while (<IN>){
	chomp;
	my ($libID,$path,$pdf,$filtered_tsv);
	if (/\/$/){$path=$_;}
	else{$path=$_."/";}
	$libID=(split/\//,$path)[-1];
	if ($ARGV[2]=~/AKM|akm/){$pdf="./".$libID.".AKM_oncoaim_lung_CN.pdf";}
	elsif ($ARGV[2]=~/CLS|cls/){$pdf="./".$libID.".oncoaim_lung_CN.pdf";}
	$filtered_tsv=$path.$libID.".report.filtered.tsv";
	my ($process_tsv,$json,$fusion,$cnv)=($filtered_tsv,$filtered_tsv,$filtered_tsv,$filtered_tsv);
	$process_tsv=~s/\.report.filtered.tsv/\.processed.tsv/;
	$json=~s/\.report.filtered.tsv/\.sqm.json/;
	$cnv=~s/\.report.filtered.tsv/\.cnv.tsv/;
	$fusion=~s/\.report.filtered.tsv/\.fusion_result.tsv/;
	print OT "php $php $filtered_tsv sgi $pdf $json $template $process_tsv $fusion $cnv\n";
}
close IN;
close OT;
