#!/usr/bin/perl -w
use strict;
die "perl $0 <ID.list> <out.xls>\n" unless (@ARGV ==2);

open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT,">$ARGV[1]" or die "Error! Cannot open $ARGV[1] \n";
#print OT "SampleID\tWorkPath\tGene\tPosition\tExon\tFrequency\tHGVsc\tHGVsp\tClin_Sig\n";

my (%hash_qc,%hash_report,%hash_benign,%hash_cnv,%var_report,%var_benign,%var_cnv);
my @sample_IDs;

while(<IN>){
	chomp;
	my $libID=$_;

	my @qc;#存放QC信息
#	my (@pathgenic, @likely_pathgenic, @uncertain, @inconlusive, @benign, @cnvs);#分类存放结果
		
	my $workspace_name="report_"."$libID";
	my $workspace_find=`find /media/pluto/Riskcare53/Data -type d -name "$workspace_name"`;
	my $workspace_path=(split/\n|\t/,$workspace_find)[-1];#如果有多次分析结果，只保留最新的一次
	chomp $workspace_path;#分析结果路径
	
	my $sample_ID="$libID"."="."$workspace_path";
	push @sample_IDs, $sample_ID;
	
	my $qc_name="$libID"."*_QCtable.txt";
	my $qc_report=`find "$workspace_path" -name "$qc_name"`;
	chomp $qc_report;
	
	my ($tsv_name, $tsv);
	if ($libID=~/-FF\d/){ #组织样本
		$tsv_name="$libID"."*_somatic.tsv"; 
		$tsv=`find "$workspace_path" -name "$tsv_name"`;
	}
	else{ #血液样本
		$tsv_name="$libID"."*_germline.tsv";
		$tsv=`find "$workspace_path" -name "$tsv_name"`;
	}
	chomp $tsv;
		
	my $cnv_gene_name="$libID"."*gene_CNV.tsv";
	my $cnv_gene_tsv=`find "$workspace_path" -name "$cnv_gene_name"`;
	chomp $cnv_gene_tsv;

	my $cnv_exon_name="$libID"."*exon_CNV.tsv";
	my $cnv_exon_tsv=`find "$workspace_path" -name "$cnv_exon_name"`;
	chomp $cnv_exon_tsv;

	print "$libID Start...\n";
	
#处理QC信息
	open QC,"$qc_report" or die "Open $qc_report error!!\n";
	while (<QC>){
		chomp;
		if($_=~/Total reads number/){my @temp=split/\t/;if ($temp[1]<5){$qc[0]="$temp[1]"."M_UNPASS";}else{$qc[0]="$temp[1]"."M";}}
		elsif($_=~/Reads mapping rate/){my @temp=split/\t/;$qc[1]=$temp[1];}
		elsif($_=~/Capture efficiency rate on target regions/){my @temp=split/\t/;$qc[2]=$temp[1];}#不用输出
		elsif($_=~/Probe coverage mean/){my @temp=split/\t/;if ($temp[1]<1000){$qc[3]="$temp[1]"."_UNPASS";}else{$qc[3]=sprintf "%d",$temp[1];}}
		elsif($_=~/Probe Uniformity/){my @temp=split/\t/;$qc[4]=$temp[1];}
		elsif($_=~/Fraction of official target covered with at least 200X/){my @temp=split/\t/;$qc[5]=$temp[1];}
	}close QC;
	$hash_qc{$sample_ID}=join "\t",$qc[0],$qc[1],$qc[3],$qc[4],$qc[5];#记录QC
	
#处理SNV
	open TSV,"$tsv" or die "Open $tsv result error!!\n";
	while(<TSV>){
		chomp;
		next if(/Chromosome/);
		if ($_=~/(B|b)enign/){
			my @a=split/\t/;
			my $pos="$a[0]".":"."$a[1]";
			$a[18]=~s/\/.+//;
			my $exon="$a[17]"."$a[18]";
			my $maf=sprintf "%.2f",$a[6];
			$a[20]=~s/ENST.+:c/c/;
			my $cdna=$a[20];
			my $aa=$a[21];
			if ($aa=~/ENST.+\(p\.=\)/){$aa='p.=';}
			else{$aa=~s/ENSP.+:p/p/;}
			$a[42]=~s/\d-//;
			my $sig=$a[42];
			my $key=join "\t",$a[12],$pos,$exon,$cdna,$aa,$sig;
			$hash_benign{$sample_ID}{$key}=$maf;
			$var_benign{$key}+=1;
		}
		else{
			my @a=split/\t/;
			my $pos="$a[0]".":"."$a[1]";
			$a[18]=~s/\/.+//;
			my $exon="$a[17]"."$a[18]";
			my $maf=sprintf "%.2f",$a[6];
			$a[20]=~s/ENST.+:c/c/;
			my $cdna=$a[20];
			my $aa=$a[21];
			if ($aa=~/ENST.+\(p\.=\)/){$aa='p.=';}
			else{$aa=~s/ENSP.+:p/p/;}
			$a[42]=~s/\d-//;
			my $sig=$a[42];
			my $key=join "\t",$a[12],$pos,$exon,$cdna,$aa,$sig;
			$hash_report{$sample_ID}{$key}=$maf;
			$var_report{$key}+=1;
		}
	}close TSV;
		
#处理CNV
	open CNV1,"$cnv_gene_tsv" or die "Open $libID cnv_gene_tsv result error!!\n";
	while(<CNV1>){
		chomp;
		if(/Gene_Symbol/){next;}
		else {
			my @b=split/\t/;
			my $gene=$b[0];
			my $pos=$b[1];
			my $ploidy=$b[2];
			my $Zscore=$b[3];
			my $key=join "\t",$gene,$pos,"-";
#			$key="gene_CNV:"."$show";
			if ($ploidy<1.2){
#				push @cnvs,$show;
				$hash_cnv{$sample_ID}{$key}="$ploidy"."|"."$Zscore";
				$var_cnv{$key}+=1;
#				print OT "$sample_ID\t$show\n";
			}
		}
	}close CNV1;
	
	open CNV2,"$cnv_exon_tsv" or die "Open $libID cnv_exon_tsv result error!!\n";
	while(<CNV2>){
		chomp;
		if(/Gene_Symbol/){next;}
		else {
			my @b=split/\t/;
			my $gene=$b[0];
			my $exon="exon"."$b[1]";
			my $pos=$b[2];
			my $ploidy=$b[3];
			my $Zscore=$b[4];
			my $key=join "\t",,$gene,$pos,$exon;
#			$show="exon_CNV:"."$show";
			if ($ploidy<1.2){
#				push @cnvs,$show;
				$hash_cnv{$sample_ID}{$key}="$ploidy"."|"."$Zscore";
				$var_cnv{$key}+=1;
#				print OT "$sample_ID\t$show\n";
			}
		}
	}close CNV2;
#	for (my $i=0;$i<=$#cnvs;$i++){$hash_cnv{$sample_ID}{$cnvs[$i]}=1;$hash_cnv{$cnvs[$i]}+=1;} #记录gene_CNV
#	print "$libID read all files done!\n";
}close IN;

#打印非良性的SNV matrix
print OT "Reported SNV results:\n";
print OT "Gene\tPosition\tExon\tHGVsc\tHGVsp\tClin_Sig\t";
for (my $i=0;$i<=$#sample_IDs;$i++){print OT "$sample_IDs[$i]\t";}
print OT "\n";
foreach my $k (sort keys %var_report){
	print OT "$k\t";
	for (my $i=0;$i<=$#sample_IDs;$i++){
		if (exists $hash_report{$sample_IDs[$i]}{$k}){
			print OT "$hash_report{$sample_IDs[$i]}{$k}\t";
		}
		else{print OT "\t";}
	}print OT "\n";
}
print OT "\n\n";

#打印CNV matrix
print OT "CNV results:\n";
foreach my $k (sort keys %var_cnv){
	print OT "$k\t\t\t\t";
	for (my $i=0;$i<=$#sample_IDs;$i++){
		if (exists $hash_cnv{$sample_IDs[$i]}{$k}){
			print OT "$hash_cnv{$sample_IDs[$i]}{$k}\t";
		}
		else{print OT "\t";}
	}print OT "\n";
}
print OT "\n\n";

#打印良性位点matrix
print OT "Benign Site:\n";
foreach my $k (sort keys %var_benign){
	print OT "$k\t";
	for (my $i=0;$i<=$#sample_IDs;$i++){
		if (exists $hash_benign{$sample_IDs[$i]}{$k}){
			print OT "$hash_benign{$sample_IDs[$i]}{$k}\t";
		}
		else{print OT "\t";}
	}print OT "\n";
}
print OT "\n\n";
#打印QC matrix
print OT "Sample's QC:\n";
print OT "SampleID\tTotal_reads\tMapping_rate\tCoverage_mean\tUniformity\tTarget_cover_rate_200X\n";
for (my $i=0;$i<=$#sample_IDs;$i++){
	if (exists $hash_qc{$sample_IDs[$i]}){print OT "$sample_IDs[$i]\t$hash_qc{$sample_IDs[$i]}\n"}
}
close OT;

