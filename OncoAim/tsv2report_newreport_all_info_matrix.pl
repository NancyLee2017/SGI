#!/usr/bin/perl
use strict;
#以matrix格式输出OncoAimDNA的突变位点和QC,以及PGKB位点（含depth)
#提供clinvar注释

die "perl $0 <in.report.extra.clinsig.tsv.list> <out.matrix.xls>\n" unless (@ARGV ==2);
#The input list should be a list of *.report.extra.clinsig.tsv"
open IN,"$ARGV[0]" or die "Error! Cannot open input: $ARGV[0] !!\n";
open OT,">$ARGV[1]" or die "Error! Cannot open output: $ARGV[1] !!\n";

my (@sample,@IDs);
my (%hash_var, %var_key, %hash_pgkb, %pgkb_key, %qc);

my @tl=('Total_read','Mapped_read','Mapped_rate','Ontarget_read','Ontarget_rate','Average_amplicon_coverage','Uniformity');

my $ClinVar_vcf="/data/home/tinayuan/Database/ClinVar/clinvar.vcf";
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

while(<IN>){
	chomp;
	my $path=$_;
	my @a=split/\//;
	my @b=split/_/,$a[-2];
	my $sampleID=shift @b;
	my $sample_path=join "=",$sampleID,$path;
	push @sample,$sample_path;
	#report.extra.tsv文件路径
	my $report=$_;
	$report=~s/report.extra.clinsig.tsv/report.extra.tsv/;
	#qc文件路径
	my $json_path=$_;
	$json_path=~s/report.extra.clinsig.tsv/sqm.json/;
	my $json_ID=join "=",$sampleID,$json_path;
	push @IDs,$json_ID;
	#var_depth文件(variants.report.txt)路径
	my @p=split(/\//,$_);
	$p[2]=~s/new_report/workspace/;
	$p[3]=$p[3]."/Variants/".$sampleID."*/";
	my $txt_path=join"/",$p[0],$p[1],$p[2],$p[3];
	my $txt=`find $txt_path -name "*variants.report.txt"`;
	chomp $txt;
	
	open FILE1,"$path" or die "Error! Cannot open tsv file: $path !!\n";
	while(<FILE1>){
		next if (/^Gene/);
		chomp;
		my @c=split/\t/;
		my $gene=$c[0];
		my $position="chr".$c[2].":".$c[3];
		my $ref=$c[4];
		my $var=$c[5];
		my $dna_change=join "/",$c[4],$c[5];
		my $var_type=$c[6];
		my $genotype=$c[7];
		my $PGKB_type=$c[9];
		my $locus=$c[10];
		chomp $c[12];
		my $freq=$c[12]/100;
		
		my $hgv_sc=$c[13];
		my $hgv_sp=$c[14];
		my $location=$c[16];
		if ($c[16]=~/Exon/){$location=$c[16].$c[17];}
		elsif($c[16]=~/Intron/){$location=$c[16].$c[18];}
		my $section=$c[19];
		my $old_pos=$position;
		if($var_type=~/indel/){$c[3]=$c[3]+1;$old_pos="chr".$c[2].":".$c[3];}
		else{$old_pos=$position;}
		my $pos_var=join ":",$position,$ref,$var;
		my ($transcript,$depth);
		
		#查找transcript信息
		open (REPORT,"$report") || print "Error! Cannot open $report \n";
		while (<REPORT>){
			chomp;
			my @temp=split/\t/;
			my $pos=join ":",$temp[0],$temp[1],$temp[2],$temp[3];
			if ($pos eq $pos_var){$transcript=$temp[36];}
			else{next;}
		}close REPORT;
		
		#查找depth信息
		open (TXT,"$txt") || print "Error! Cannot open old report of $sampleID \n";
		while(<TXT>){
			chomp;
			my @temp=split/\t/;
			if($temp[0] eq $old_pos) {$depth=$temp[4];}
			else{next;}
		}close TXT;
		
		#记录PGKB信息
		if($section=~/^PGKB/){
			my $k=join "\t",$gene,$locus,$position,$ref;
			$pgkb_key{$k}+=1;
			$hash_pgkb{$sample_path}{$k}=join "|",$genotype,$PGKB_type,$depth;
		}
		#记录突变信息
		else{
			my $k=join "\t",$gene,$position,$location,$ref,$var,$locus,$hgv_sc,$hgv_sp,$transcript,$var_type;
			$var_key{$k}+=1;
			$hash_var{$sample_path}{$k}=join "|",$freq,$depth;
		}
	}close FILE1;
	
	#准备QC信息
	open (JSON,"$json_path") || print "Cannot open $json_path !\n";
	while(<JSON>){
		$_=~s/\"//g;
		$_=~s/\}//g;
		my @b=split/,/;
		for (my $i=0;$i<=$#b;$i++){$b[$i]=~s/.+:\s//;}
		$qc{$tl[0]}{$json_ID}=$b[3];
		$qc{$tl[1]}{$json_ID}=$b[5];
		my $map_rate=$b[5]/$b[3];
		$map_rate=sprintf "%.3f",$map_rate;
		$qc{$tl[2]}{$json_ID}=$map_rate;
		$qc{$tl[3]}{$json_ID}=$b[0];
		my $tar_rate=$b[0]/$b[5];
		$tar_rate=sprintf "%.3f",$tar_rate;
		$qc{$tl[4]}{$json_ID}=$tar_rate;
		$qc{$tl[5]}{$json_ID}=$b[1];
		$b[2]=$b[2]."%";
		$qc{$tl[6]}{$json_ID}=$b[2];
	}close JSON;
	print "$sampleID DONE!\n";
}

#输出突变位点
print OT "GeneName\tPosition\tLocation\tRef\tVar\tLocusName\tcDNA_change\tProtein_change\tTranscript\tVarType\t";
for(my $i=0;$i<=$#sample;$i++){print OT "$sample[$i]\t";}
print OT "\n";
foreach my $k(sort keys %var_key){
	print OT "$k\t";
	for (my $i=0;$i<=$#sample;$i++){
		if (exists $hash_var{$sample[$i]}{$k}){print OT "$hash_var{$sample[$i]}{$k}\t";}
		else {print OT "\t";}
	}
	my @t=split/\t/,$k;
	my $clin_key=join "\t",$t[1],$t[3],$t[4];
	if (exists $ClinVar{$clin_key}){
		print OT "$ClinVar{$clin_key}\t";
	}
	else {print OT "\t";}
	print OT "\n";
}
print OT "\n\n";

#输出PGKB位点
print OT "\t\t\t\t\tPGKB_matrix\n";
print OT "\t\t\t\t\t\tGeneName\tLocusName\tPosition\tRef\t";
for(my $i=0;$i<=$#sample;$i++){print OT "$sample[$i]\t";}
print OT "\n";
foreach my $k(sort keys %pgkb_key){
	print OT "\t\t\t\t\t\t$k\t";
	for (my $i=0;$i<=$#sample;$i++){
		if (exists $hash_pgkb{$sample[$i]}{$k}){print OT "$hash_pgkb{$sample[$i]}{$k}\t";}
		else {print OT "\t";}
	}
	print OT "\n";
}
print OT "\n\n";

#输出QC信息
print OT "\t\t\t\t\t\t\t\tQC_matrix\n";
print OT "\t\t\t\t\t\t\t\t\tSampleID\t";
for(my $i=0;$i<=$#IDs;$i++){print OT "$IDs[$i]\t";}
print OT "\n";
foreach my $k (@tl) {
	print OT "\t\t\t\t\t\t\t\t\t$k\t";
	for(my $i=0;$i<=$#IDs;$i++){
		if (exists $qc{$k}{$IDs[$i]}){print OT "$qc{$k}{$IDs[$i]}\t";}
		else {print OT "\t";}
	}
	print OT "\n";
}
close OT;



