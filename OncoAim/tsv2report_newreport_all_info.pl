#!/usr/bin/perl
use strict;
#同时输出OncoAimDNA的突变位点和QC,以及PGKB位点
#提供clinvar注释对照

die "perl $0 <in.report.extra.clinsig.tsv.list> <out.matrix.xls>\n" unless (@ARGV ==2);
#The input list should be a list of *.report.extra.clinsig.tsv"
open IN,"$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT,">$ARGV[1]" or die "Error! Cannot open $ARGV[1] \n";

print OT "SampleID\tGeneName\tPosition\tLocation\tRef\tVar\tFrequency\tDepth\tLocusName\tcDNA_change\tProtein_change\tTranscript\tVarType\tClin_Sig\n";

my @sample;
my %hash;
my %key;
my @IDs;
my %qc;
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
	my $json_path=$_;
	$json_path=~s/report.extra.clinsig.tsv/sqm.json/;
	my $report=$_;
	$report=~s/report.extra.clinsig.tsv/report.extra.tsv/;
	my @b=split/_/,$a[-2];
	my $sampleID=shift @b;
	push @IDs,$sampleID;
	my $file=join "=",$sampleID,$path;
	push @sample,$file;
	my @main;
	my @low;
	
	my @p=split(/\//,$path);
	$p[2]=~s/new_report/workspace/;
	$p[3]=$p[3]."/Variants/".$sampleID."*/";
	my $workspace=join"/",$p[0],$p[1],$p[2],$p[3];
#	print "$workspace\n";
	my $txt=`find $workspace -name "*variants.report.txt"`;
	chomp $txt;
	
	open FILE1,"$_" or die "Error! Cannot open $_\n";
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
		my $freq=$c[12];
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
		my ($clin_sig,$transcript,$depth);
		
		my $clin_key=join "\t",$position,$ref,$var;
		if (exists $ClinVar{$clin_key}){
			$clin_sig=$ClinVar{$clin_key};
		}
		else {$clin_sig='Not included in ClinVar';}
		
		
		open (REPORT,"$report") || print "Error! Cannot open $report \n";
		while (<REPORT>){
			chomp;
			my @temp=split/\t/;
			my $pos=join ":",$temp[0],$temp[1],$temp[2],$temp[3];
			if ($pos eq $pos_var){$transcript=$temp[36];}
			else{next;}
		}close REPORT;
		
		open (TXT,"$txt") || print "Error! Cannot open old report of $sampleID \n";
		while(<TXT>){
			chomp;
			my @temp=split/\t/;
			if($temp[0] eq $old_pos) {$depth=$temp[4];}
			else{next;}
		}close TXT;
		
		
		if ($section=~/^Main/){
			my $show=join "\t",$sampleID,$gene,$position,$location,$ref,$var,$freq,$depth,$locus,$hgv_sc,$hgv_sp,$transcript,$var_type,$clin_sig,$path;
#			print "$clin_key\n";
			push @main,$show;
		}
		elsif($section=~/^Low/){
			my $show=join "\t",$sampleID,$gene,$position,$location,$ref,$var,$freq,$depth,$locus,$hgv_sc,$hgv_sp,$transcript,$var_type,$clin_sig,$path;
			push @low,$show;
		}
		elsif($section=~/^PGKB/){#记录PGKB信息
			my $k=join "\t",$gene,$locus;
			$key{$k}+=1;
			$hash{$sampleID}{$k}=join "\t",$position,$ref,$var,$genotype,$PGKB_type,$hgv_sc,$hgv_sp,$freq,$depth,;
		}
	}close FILE1;
	#按次序输出突变
	for (my $i=0;$i<=$#main;$i++){print OT "$main[$i]\n";}
	for (my $i=0;$i<=$#low;$i++){print OT "$low[$i]\n";}
	if ((!@main)&&(!@low)){print OT "$sampleID\tNo_Variants_were_detected\n";}
#	print "$sampleID done!\n";

	open (JSON,"$json_path") || print "Cannot open $json_path !\n";
	while(<JSON>){
		$_=~s/\"//g;
		$_=~s/\}//g;
		my @b=split/,/;
		for (my $i=0;$i<=$#b;$i++){$b[$i]=~s/.+:\s//;}
		my $map_rate=$b[5]/$b[3];
		$map_rate=sprintf "%.3f",$map_rate;
		my $tar_rate=$b[0]/$b[5];
		$tar_rate=sprintf "%.3f",$tar_rate;
		$b[2]=$b[2]."%";
		my $show=join "\t",$b[3],$b[5],$map_rate,$b[0],$tar_rate,$b[1],$b[2];
		$qc{$sampleID}=$show;
	}close JSON;
}
close IN;

print OT "\n\n";

print OT "QC_info\n";#输出QC
print OT "SampleID\tTotal_read\tMapped_read\tMapped_rate\tOntarget_read\tOntarget_rate\tAverage_amplicon_coverage\tUniformity\n";
for(my $i=0;$i<=$#IDs;$i++){
	if(exists $qc{$IDs[$i]}){print OT "$IDs[$i]\t$qc{$IDs[$i]}\n";}
	else{print OT "$IDs[$i]\tQC_missing\n";}
}


print OT "\n\n";

print OT "PGKB_info\n";#输出PGKB
print OT "SampleID\tGeneName\tLocusName\tPosition\tRef\tAlt\tGenotype\tPGKB_type\tcDNA_change\tProtein_change\tFrequency\tDepth\n";

for(my $i=0;$i<=$#IDs;$i++){
	foreach my $sk(sort keys %key){
			print OT "$IDs[$i]\t$sk\t";
			if(exists $hash{$IDs[$i]}{$sk}){print OT "$hash{$IDs[$i]}{$sk}\n";}
			else{print OT "NA\n";}
		}
}

close OT;

