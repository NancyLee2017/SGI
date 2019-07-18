#!/usr/bin/perl -w
use strict;

die "perl $0 <pdf.list> <LDT.xls>\n" unless (@ARGV ==2);

open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT,">$ARGV[1]" or die "Open $ARGV[1] error!\n";
print OT "LibID\tGene\tLocus\tExon\tGenotype\tRef\tVariant\tAA_change\tType\tConsequence\tClin_Sig\tAverage_cover\tKnown_site_cover_rate\n";
my @sampleIDs;
my (%hash,%posi);

while(<IN>){
	chomp;
	my $pdf_path=$_;
	my $pdf=(split/\//,$pdf_path)[-1];
	my $libID=(split/_/,$pdf)[1];
	my $txt="$libID".".txt";
#	print "$txt\n";
=pod
	#寻找tsv文件
	my $tsv_name="*"."$libID"."*"."report.tsv";
	my $tsv_find=`find /BRCAim_Luigi/workspace/ -name "$tsv_name"`;
	my $tsv=(split/\n|\t/,$tsv_find)[-1];
	chomp $tsv;
#	print "$tsv\n";

	#给ID后加上tsv路径
	my $sampleID="$libID"."="."$tsv";
	push @sampleIDs,$sampleID;
=cut
	#进行PDF格式转换
	my $change=system("/home/zhouwang/Scripts/xpdfbin/bin64/pdftotext -raw $pdf_path $txt");
	if ($change!=0){print "Error: Change $pdf_path failed!\n";}
#	if ($change==0){print "Change $pdf_path success!\n";}
	
	#处理txt文件,去除空行
	my $txt2="$txt"."_s";
	open TXT,"$txt" or die "Cannot open $txt !\n";
	open TXT2,">$txt2" or die "Cannot open $txt2 !\n";
#	print "open $txt success!\n";
#	my $empty=0;
	while(<TXT>){
		if (/^$/){
#			$empty++; print"$empty\n";
			next;
		}
		else{print TXT2 "$_";}
	}close TXT;
	close TXT2;
	
	my $parse=system("perl /home/hongyanli/script/BRCA/ParsePDF.pl $txt2");
	if ($parse!=0){print "Error: Parse $txt2 failed!\n";}
#	if ($parse==0){print "Parse $txt2 success!\n";}
	
	#从out文件中提取突变点信息,整理成LDT格式
	my $out="$libID"."_s.out";
	open FILE,"$out" or die "Cannot open $out !\n";
#	print "open $out success!\n";
	while(<FILE>){
		chomp;
		if (/^$/){next;}
		my @t=split/\t/;
		my $gene=$t[1];
		my $locus=$t[2];
		my $exon=$t[3];
		my $genotype=$t[4];
		my $ref=$t[5];
		my $variant=$t[6];
		my $AAchange=$t[7];
		my $type=$t[8];
		my $consequence=$t[9];
		my $ClinSig=$t[10];
		my $mean_coverage=$t[11];
		my $known_site_rate=$t[12];
		my $k=join "\t",$libID,$gene,$locus,$exon,$genotype,$ref,$variant,$AAchange,$type,$consequence,$ClinSig,$mean_coverage,$known_site_rate;
		print OT "$k\n";
#		my $o="NA";
#		my $site=(split/:/,$locus)[-1];
=pod		
		#从tsv中提取位点depth及频率
		open TSV,"$tsv" or die "Cannot open $_ !\n";
		while(<TSV>){
			chomp;
			if ($_=~/$site/){
				my @a=split/\t/;
				$a[6]=sprintf "%.3f",$a[6];
				$o=$a[6]."|".$a[7];
			}
			else{next;}
		}close TSV;

		$hash{$sampleID}{$k}=$o;
		$posi{$k}+=1;
=cut		
	}close FILE;

}close IN;
