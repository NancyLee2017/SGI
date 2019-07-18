#!/usr/bin/perl -w
use strict;

die "perl $0 <pdf.list> <txt.matrix.xls>\n" unless (@ARGV ==2);

open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";

my @sampleIDs;
my (%hash,%posi);

while(<IN>){
	chomp;
	my $pdf_path=$_;
	my $pdf=(split/\//,$pdf_path)[-1];
	my $libID=(split/_/,$pdf)[1];
	my $txt="$libID".".txt";
#	print "$txt\n";
	
	#定位tsv文件
	my $run_name=(split/\//,$pdf_path)[-2];
	my $foldname=$pdf;
	$foldname=~s/.report-tsv.pdf//;
	my $tsv="/BRCAim_Luigi/workspace/".$run_name."/".$foldname."/".$foldname.".report.tsv";
#	print "$tsv\n";
#	chomp $tsv;
#	print "$tsv\n";
	
	#给ID后加上tsv路径
	my $sampleID="$libID"."="."$tsv";
	push @sampleIDs,$sampleID;
	
	#进行PDF格式转换
	my $change=system("/home/zhouwang/Scripts/xpdfbin/bin64/pdftotext -raw $pdf_path $txt");
	if ($change!=0){print "Error: Change $pdf_path failed!\n";}
#	if ($change==0){print "Change $pdf_path success!\n";}
	
	#处理txt文件
	my $txt2="$txt"."_s";
	open TXT,"$txt" or die "Cannot open $txt !\n";
	open TXT2,">$txt2" or die "Cannot open $txt2 !\n";
#	print "open $txt success!\n";
	my $empty=0;
	while(<TXT>){
		if (/^$/){$empty++; print"$empty\n";}
		else{print TXT2 "$_";}
	}close TXT;
	close TXT2;
	
	my $parse=system("perl /home/hongyanli/script/BRCA/ParsePDF.pl $txt2");
	if ($parse!=0){print "Error: Parse $txt2 failed!\n";}
#	if ($parse==0){print "Parse $txt2 success!\n";}
	
	#从out文件中提取突变点信息
	my $out="$libID"."_s.out";
	open FILE,"$out" or die "Cannot open $out !\n";
#	print "open $out success!\n";
	while(<FILE>){
		if (/^$/){next;}
		my @t=split/\t/;
		my $gene=$t[1];
		my $locus="chr"."$t[2]";
		my $exon=$t[3];
		my $genotype=$t[4];
		$genotype=~s/.+\///;
		my $ref=$t[5];
		my $variant=$t[6];
		my $AAchange=$t[7];
		my $type=$t[8];
		my $consequence=$t[9];
		my $ClinSig=$t[10];
		my $k=join "\t",$gene,$locus,$exon,$ref,$genotype,$variant,$AAchange,$type,$consequence,$ClinSig;
#		print "$k\n";
		my $o=" ";
		my $site=(split/:/,$locus)[-1];
		
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
		
	}close FILE;

}close IN;


open OT,">$ARGV[1]" or die "Open $ARGV[1] error!\n";
print OT "Gene\tLocus\tExon\tRef\tGenotype\tHGVsc\tHGVsp\tType\tConsequence\tClin_Sig\t";

for(my $i=0;$i<=$#sampleIDs;$i++){print OT "$sampleIDs[$i]\t";}
print OT "\n";
foreach my $k(sort keys %posi){
	print OT "$k\t";
	for(my $i=0;$i<=$#sampleIDs;$i++){
		if(exists $hash{$sampleIDs[$i]}{$k}){print OT "$hash{$sampleIDs[$i]}{$k}\t";}
		else{print OT " \t";}
	}
	print OT "\n";
}close OT;

#删除中间文件
system("rm *out *txt_s")
#system("rm *-P.txt")
