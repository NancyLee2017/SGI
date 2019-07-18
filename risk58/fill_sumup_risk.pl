#!/usr/bin/perl -w
use strict;

die "perl $0 <ID.list> <out.xls>\n" unless (@ARGV ==2);

open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT,">$ARGV[1]" or die "Error! Cannot open $ARGV[1] \n";

my @reports;
my %hash;

while(<IN>){
	chomp;
	my @t=split/\t/;
#处理PGM数据
	if ($t[0]=~/.+(-P)/){
	#PGM数据的输入list必须有3列，第一列是LibID,第二列是IonXpressXXX,第三列填写PGM_run在mars的路径
		if($t[1]!~/IonXpress/){die "Error: Missing bam_ID!";}#检查IonXpress编号是否存在
		my $libID=$t[0];
		my $bam_ID=$t[1];
		my $path=$t[2];#PGM_run在mars的路径
		my $filename="$bam_ID"."*.bam";
		my $bam_path=`find $path -name "$filename"`;
		chomp $bam_path;#获得数据路径
		
		my $workspace_name="$libID"."*";
		my $workspace_path=`find /OncoAim_PGM_denovo/workspace/ -type d -name "$workspace_name"`;
		chomp $workspace_path;#获得分析结果路径
		
		my $report_name="$libID"."*_variant_report.txt";
		my $report=`find /OncoAim_PGM_denovo/report/ -name "$report_name"`;
		chomp $report;
		my $qc;#存放QC信息
		
		if ($report=~/_variant_report.txt/){#OncoAim DNA样本
			open TXT,"$report" or die "Open $report error!!\n";
			while (<TXT>){
				chomp;
				if($_=~/Median RD\| Uniformity/){
					my $temp=<TXT>;
					$qc=<TXT>;
					chomp $qc;
					$qc=~s/\s+//g;
					my @q=split/\|/,$qc;
					shift @q;
					$qc=join "\t",@q;
				}
			}close TXT;
		}
		else {
			my $fusion_report_name="$libID"."*_fusion_report.txt";
			my $fusion_report=`find $workspace_path -name "$fusion_report_name"`;
			chomp $fusion_report;
			if ($fusion_report=~/_fusion_report.txt/){#OncoAimRNA样本
				open TXT,"$fusion_report" or die "Open $fusion_report error!!\n";
				my ($mapped_reads,$mapping_rate,$total_reads);
				while (<TXT>){
					chomp;
					if ($_=~/Total_mapped_reads/){my @a=split/\t/;$mapped_reads=$a[4];}
					elsif($_=~/Mapping_rate/){my @b=split/\t/;$mapping_rate=$b[4];}
				}close TXT;
				$total_reads=($mapped_reads/$mapping_rate)*100;
				$total_reads=sprintf "%d",$total_reads;
				$mapping_rate=sprintf "%.1f%%",$mapping_rate;
				$qc=join "\t",$total_reads,$mapped_reads,$mapping_rate;
			}
			else {$qc="Not OncoAim Sample"}
		}
		print OT "$libID\t$bam_path\t\t$workspace_path\t$qc\n";
	}
#处理nextseq_02数据
	elsif ($t[0]=~/.+(-M)/){
		my @qc;#存放QC信息
		my @pathgenic;
		my @likely_pathgenic;
		my @uncertain;
		my @inconlusive;
		my @cnvs;
		
		my $libID=$t[0];
#		my $filename="$libID"."*_R1*.gz";
#		my $gz_path=`find /media/SeqStore/nextseq_02/ -name "$filename"`;
#		chomp $gz_path;
		my $workspace_name="report_"."$libID";
		my $workspace_find=`find /media/pluto/Riskcare53/Data/ -type d -name "$workspace_name"`;
		my $workspace_path=(split/\n|\t/,$workspace_find)[-1];
		chomp $workspace_path;#分析结果路径
		my $qc_name="$libID"."*_QCtable.txt";
		my $qc_report=`find "$workspace_path" -name "$qc_name"`;
		chomp $qc_report;
		
		my $tsv_name="$libID"."*_germline.tsv";
		my $tsv=`find "$workspace_path" -name "$tsv_name"`;
		chomp $tsv;
		
		my $cnv_gene_name="$libID"."*gene_CNV.tsv";
		my $cnv_gene_tsv=`find "$workspace_path" -name "$cnv_gene_name"`;
		chomp $cnv_gene_tsv;
#		print "$cnv_gene_tsv\n";
		my $cnv_exon_name="$libID"."*exon_CNV.tsv";
		my $cnv_exon_tsv=`find "$workspace_path" -name "$cnv_exon_name"`;
		chomp $cnv_exon_tsv;
#		print "$cnv_exon_tsv\n";
		print "$libID Start...\n";
		if ($qc_report=~/_QCtable.txt/){#打开QC信息
			open TXT,"$qc_report" or die "Open $qc_report error!!\n";
			while (<TXT>){
				chomp;
				if($_=~/Total reads number/){my @temp=split/\t/;if ($temp[1]<5){$temp[1]=$temp[1]*1000000;$qc[0]="$temp[1]"."_UNPASS";}else{$qc[0]=$temp[1]*1000000;}}
				elsif($_=~/Reads mapping rate/){my @temp=split/\t/;$qc[1]=$temp[1];}
				elsif($_=~/Capture efficiency rate on target regions/){my @temp=split/\t/;$qc[2]=$temp[1];}
				elsif($_=~/Probe coverage mean/){my @temp=split/\t/;if ($temp[1]<300){$qc[3]="$temp[1]"."_UNPASS";}else{$qc[3]=sprintf "%d",$temp[1];}}
				elsif($_=~/Probe Uniformity/){my @temp=split/\t/;$qc[4]=$temp[1];}
				elsif($_=~/Fraction of official target covered with at least 200X/){my @temp=split/\t/;$qc[5]=$temp[1];}
			}close TXT;
		}
		open TSV,"$tsv" or die "Open $libID germline_tsv result error!!\n";#打开SNV结果
		while(<TSV>){
			chomp;
			if($_=~/5-Pathogenic/){
				my @a=split/\t/;
				my $pos="$a[0]".":"."$a[1]";
				$a[18]=~s/\/.+//;
				my $exon="$a[17]"."$a[18]";
				my $maf=sprintf "%.2f%%",$a[6]*100;
				$a[20]=~s/ENST.+:c/c/;
				my $cdna=$a[20];
				$a[21]=~s/ENSP.+:p/p/;
				my $aa=$a[21];
				$a[42]=~s/\d-//;
				my $sig=$a[42];
				my $show=join " ",$a[12],$pos,$exon,$maf,$cdna,$aa,$sig;
				push @pathgenic,$show;
			}
			elsif($_=~/3-Uncertain/){
				my @a=split/\t/;
				my $pos="$a[0]".":"."$a[1]";
				$a[18]=~s/\/.+//;
				my $exon="$a[17]"."$a[18]";
				my $maf=sprintf "%.2f%%",$a[6]*100;
				$a[20]=~s/ENST.+:c/c/;
				my $cdna=$a[20];
				$a[21]=~s/ENSP.+:p/p/;
				my $aa=$a[21];
				$a[42]=~s/\d-//;
				my $sig=$a[42];
				my $show=join " ",$a[12],$pos,$exon,$maf,$cdna,$aa,$sig;
				push @uncertain,$show;
			}
			elsif($_=~/4-Likely(.+)(P|p)athogenic/){
				my @a=split/\t/;
				my $pos="$a[0]".":"."$a[1]";
				$a[18]=~s/\/.+//;
				my $exon="$a[17]"."$a[18]";
				my $maf=sprintf "%.2f%%",$a[6]*100;
				$a[20]=~s/ENST.+:c/c/;
				my $cdna=$a[20];
				$a[21]=~s/ENSP.+:p/p/;
				my $aa=$a[21];
				$a[42]=~s/\d-//;
				my $sig=$a[42];
				my $show=join " ",$a[12],$pos,$exon,$maf,$cdna,$aa,$sig;
				push @likely_pathgenic,$show;
			}
			elsif($_=~/0-Inconclusive/){
				my @a=split/\t/;
				my $pos="$a[0]".":"."$a[1]";
				$a[18]=~s/\/.+//;
				my $exon="$a[17]"."$a[18]";
				my $maf=sprintf "%.2f%%",$a[6]*100;
				$a[20]=~s/ENST.+:c/c/;
				my $cdna=$a[20];
				$a[21]=~s/ENSP.+:p/p/;
				my $aa=$a[21];
				$a[42]=~s/\d-//;
				my $sig=$a[42];
				my $show=join " ",$a[12],$pos,$exon,$maf,$cdna,$aa,$sig;
				push @inconlusive,$show;
			}
		}close TSV;
		
		open CNV1,"$cnv_gene_tsv" or die "Open $libID cnv_gene_tsv result error!!\n";#打开SNV结果
		while(<CNV1>){
			chomp;
			if(/Gene_Symbol/){next;}
			else {
				my @b=split/\t/;
#				my $gene=$b[0];
#				my $pos=$b[1];
#				my $ploidy=$b[2];
#				my $Zscore=$b[3];
				my $show=join " ",@b;
				$show="gene_CNV:"."$show";
				push @cnvs,$show;
			}
		}close CNV1;
		
		open CNV2,"$cnv_exon_tsv" or die "Open $libID cnv_exon_tsv result error!!\n";#打开SNV结果
		while(<CNV2>){
			chomp;
			if(/Gene_Symbol/){next;}
			else {
				my @b=split/\t/;
				my $show=join " ",@b;
				$show="exon_CNV:"."$show".";";
				push @cnvs,$show;
			}
		}close CNV2;
		
		print OT "$libID\t$workspace_path\t$qc[0]\t\t$qc[1]\t\t$qc[2]\t$qc[3]\t$qc[4]\t\t$qc[5]\t";
		for (my $i=0;$i<=$#pathgenic;$i++){print OT "$pathgenic[$i];";}
		for (my $i=0;$i<=$#likely_pathgenic;$i++){print OT "$likely_pathgenic[$i];";}
		for (my $i=0;$i<=$#uncertain;$i++){print OT "$uncertain[$i];";}
		for (my $i=0;$i<=$#inconlusive;$i++){print OT "$inconlusive[$i];";}
		for (my $i=0;$i<=$#cnvs;$i++){print OT "$cnvs[$i];";}
#		print OT "\n";
		print "$libID Done!\n";
	}print OT "\n";
}
close IN;
close OT;