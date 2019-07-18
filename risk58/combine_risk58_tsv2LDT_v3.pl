#!/usr/bin/perl -w
#提供clinvar注释

use strict;
die "perl $0 <ID.list> <out.xls>\n" unless (@ARGV ==2);
my $ClinVar_vcf="/home/pluto/hongyanli/DataBase/clinvar.vcf";
my %ClinVar;

open CLINVAR,"$ClinVar_vcf" or die "Open ClinVar file Error!\n";
while(<CLINVAR>){
        chomp;
        next if($_=~/^\#/);
        my @a=split/\t/;
        my @b=split/\;/,$a[-1];
        my $clins="";
        for(my $i=0;$i<=$#b;$i++){if($b[$i]=~/(CLNSIG=)(\w+)/){$clins=$2;}}
        $a[0]="chr".$a[0];
        $a[2]="https://www.ncbi.nlm.nih.gov/clinvar/variation/".$a[2]."/";
        my $k=join ":",$a[0],$a[1];$k=join "\t",$k,$a[3],$a[4];
        my $o=join ",","ClinVar",$clins,$a[2];
        $ClinVar{$k}=$o;
}
close CLINVAR;


open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT,">$ARGV[1]" or die "Error! Cannot open $ARGV[1] \n";
print OT "SampleID\tWorkPath\tGene\tPosition\tExon\tGenotype\tRef\tAlt\tHGVsc\tHGVsp\tType\tClin_Sig\tFrequency\tDepth\tClinVar_Sig\n";

my (%hash_qc,%hash_report,%hash_benign,%hash_cnv,%var);
my @sample_IDs;

while(<IN>){
	chomp;
	my $libID=$_;

	my @qc;#存放QC信息
	my (@pathgenic, @likely_pathgenic, @uncertain, @inconlusive, @benign, @cnvs);#分类存放结果
		
	my $workspace_name="report_"."$libID";
	my $workspace_find=`find /media/pluto/Riskcare53/Data -type d -name "$workspace_name"`;
	my $workspace_path=(split/\n|\t/,$workspace_find)[-1];#如果有多次分析结果，只保留最新的一次
	chomp $workspace_path;#分析结果路径
	
	my $sample_ID="$libID"."\t"."$workspace_path";
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
		my @a=split/\t/;
                my $pos="$a[0]".":"."$a[1]";
                my $ref=$a[2];
                my $alt=$a[3];
                my $clin_key=join"\t",$pos,$ref,$alt;
                my $clin_sig;
                if (exists $ClinVar{$clin_key}){$clin_sig=$ClinVar{$clin_key};}
                else {$clin_sig='Not included in ClinVar';}
                my $type=$a[4];
                my $genotype=$a[5];
                $a[18]=~s/\/.+//;
                my $exon="$a[17]"."$a[18]";
                my $maf=sprintf "%.3f",$a[6];
                my $depth=$a[7];
                $a[20]=~s/ENST.+:c/c/;
                my $cdna=$a[20];
                $a[21]=~s/ENSP.+:p/p/;
                my $aa=$a[21];
                $a[42]=~s/\d-//;
                my $sig=$a[42];
                my $show=join "\t",$a[12],$pos,$exon,$genotype,$ref,$alt,$cdna,$aa,$type,$sig,$maf,$depth,$clin_sig;

		if($_=~/5-Pathogenic/){	push @pathgenic,$show;}
		elsif($_=~/4-Likely\sPathogenic/){push @likely_pathgenic,$show;}
		elsif($_=~/3-Uncertain/){push @uncertain,$show;}
		elsif($_=~/0-Inconclusive/){push @inconlusive,$show;}
		else{
			if ($aa=~/ENST.+\(p\.=\)/){next;}#不统计同义benign位点
			push @benign,$show;
		}
	}close TSV;
	
#记录SNV
	for (my $i=0;$i<=$#pathgenic;$i++){
#		$hash_report{$sample_ID}{$pathgenic[$i]}=1;$var{$pathgenic[$i]}+=1;
		print OT "$sample_ID\t$pathgenic[$i]\n";
	}
	for (my $i=0;$i<=$#likely_pathgenic;$i++){
#		$hash_report{$sample_ID}{$likely_pathgenic[$i]}=1;
		print OT "$sample_ID\t$likely_pathgenic[$i]\n";
	}
	for (my $i=0;$i<=$#uncertain;$i++){
#		$hash_report{$sample_ID}{$uncertain[$i]}=1;
		print OT "$sample_ID\t$uncertain[$i]\n";
	}
	for (my $i=0;$i<=$#inconlusive;$i++){
#		$hash_report{$sample_ID}{$inconlusive[$i]}=1;
		print OT "$sample_ID\t$inconlusive[$i]\n";
	}
	for (my $i=0;$i<=$#benign;$i++){
#		$hash_benign{$sample_ID}{$benign[$i]}=1;$var{$benign[$i]}+=1;
		print OT "$sample_ID\t$benign[$i]\n";
	}
	
		
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
			my $show=join "\t",$gene,$pos;
			$show="gene_CNV:"."$show";
			if ($ploidy<1.2){
				push @cnvs,$show;
				print OT "$sample_ID\t$show\n";
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
			my $show=join "\t",,$gene,$pos,$exon;
			$show="exon_CNV:"."$show";
			if ($ploidy<1.2){
				push @cnvs,$show;
				print OT "$sample_ID\t$show\n";
			}
		}
	}close CNV2;
	for (my $i=0;$i<=$#cnvs;$i++){$hash_cnv{$sample_ID}{$cnvs[$i]}=1;} #记录gene_CNV
#	print "$libID read all files done!\n";
}close IN;

print OT "\n\n\n";
print OT "SampleID\tWorkPath\tTotal_reads\tMapping_rate\tCoverage_mean\tUniformity\tTarget_cover_rate_200X\n";

for (my $i=0;$i<=$#sample_IDs;$i++){
	if (exists $hash_qc{$sample_IDs[$i]}){print OT "$sample_IDs[$i]\t$hash_qc{$sample_IDs[$i]}\n"}
}
=pod
foreach 
		print OT "$libID\t$workspace_path\t$qc[0]\t\t$qc[1]\t\t$qc[2]\t$qc[3]\t$qc[4]\t\t$qc[5]\t";
		for (my $i=0;$i<=$#pathgenic;$i++){print OT "$pathgenic[$i];";}
		for (my $i=0;$i<=$#likely_pathgenic;$i++){print OT "$likely_pathgenic[$i];";}
		for (my $i=0;$i<=$#uncertain;$i++){print OT "$uncertain[$i];";}
		for (my $i=0;$i<=$#inconlusive;$i++){print OT "$inconlusive[$i];";}
		for (my $i=0;$i<=$#cnvs;$i++){print OT "$cnvs[$i];";}
		print OT "\n";
		print "$libID Done!\n";
	}print OT "\n";
}
=cut
close OT;

