#!/usr/bin/perl
use strict;
die "perl $0 <in.report.extra.clinsig.tsv.list> <out.matrix.xls>\n" unless (@ARGV ==2);
#The input list should be a list of *.report.extra.clinsig.tsv "
open IN,"$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT,">$ARGV[1]" or die "Error! Cannot open $ARGV[1] \n";

my @sample;
my @tl=('Total_read','Mapped_read','Mapped_rate','Ontarget_read','Ontarget_rate','Average_amplicon_coverage','Uniformity');
my (%hash,%qc);
#/OncoAim_PGM_denovo/new_report/CLS_180831_pgm_chip1_20180901/WHF-FF180829025-D01-L01-P_5DL87.IonXpress_064/
while(<IN>){
	chomp;
	my ($path,$report,$json)=($_,$_,$_);
	$report=~s/report.extra.clinsig.tsv/report.extra.tsv/;
	$json=~s/report.extra.clinsig.tsv/sqm.json/;
	
	my @a=split/\//;
	my @b=split/_/,$a[-2];
	my $sampleID=shift @b;
	my $file=join "=",$sampleID,$_;
	push @sample,$file;
	
	my @p=split(/\//,$path);
	$p[2]=~s/new_report/workspace/;
	$p[3]=$p[3]."/Variants/".$sampleID."*/";
	$path=join"/",$p[0],$p[1],$p[2],$p[3];
#	print "$path\n";
	my $txt=`find $path -name "*variants.report.txt"`;
	chomp $txt;
	
	open FILE1,"$_" or die "Error! Cannot open $_\n";
	while(<FILE1>){
		next if (/^Gene/);
		chomp;
		my @c=split/\t/;
		my $maf=$c[12];
		chomp $maf;
		my $section=$c[19];
#		next if ($maf<$ARGV[2]);
		next if ($section=~/PGKB/);
		my $position="chr".$c[2].":".$c[3];
		my $gene=$c[0];
		my $exon=$c[17];
		my $ref=$c[4];
		my $alt=$c[5];
		my $freq=$maf/100;
		my $cDNA=$c[13];
		my $pro=$c[14];
#		if ($pro=~/ENSP.*\(p\.=\)/){$pro='(=)';}
#		elsif ($pro=~/ENSP.+:p\./){$pro=~s/ENSP.+:p/p/;}
		my $locus=$c[10];
		my $var_type=$c[6];
		my $old_pos=$position;
		if($var_type=~/indel/){$c[3]=$c[3]+1;$old_pos="chr".$c[2].":".$c[3];}
		else{$old_pos=$position;}
		my $pos_var=join ":",$position,$ref,$alt;
		my ($transcript,$depth);
		
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
		
		my $k=join "\t",$gene,$position,$exon,$ref,$alt,$locus,$cDNA,$pro,$transcript,$var_type;
		$hash{$k}{$file}="$freq"."|"."$depth";
#		$hash{$k}{$file}=$freq;
	}
	close FILE1;
	
	
	open JSON,"$json"or die "Error! Cannot open $json for qc\n";
		while(<JSON>){
			$_=~s/\"//g;
			$_=~s/\}//g;
			my @t=split/,/;
			for (my $i=0;$i<=$#t;$i++){$t[$i]=~s/.+:\s//;}
			my $map_rate=$t[5]/$t[3];
			$map_rate=sprintf "%.3f",$map_rate;
			my $tar_rate=$t[0]/$t[5];
			$tar_rate=sprintf "%.3f",$tar_rate;
			$qc{$tl[0]}{$file}=$t[3];
			$qc{$tl[1]}{$file}=$t[5];
			$qc{$tl[2]}{$file}=$map_rate;
			$qc{$tl[3]}{$file}=$t[0];
			$qc{$tl[4]}{$file}=$tar_rate;
			$qc{$tl[5]}{$file}=$t[1];
			$qc{$tl[6]}{$file}=$t[2]."%";
		}
		close JSON;
}
close IN;

print OT "GeneName\tPosition\tExon\tRef\tAlt\tLocusName\tcDNA_change\tProtein_change\tTranscript\tVarType\t";
for(my $i=0;$i<=$#sample;$i++){print OT "$sample[$i]\t";}print OT "\n";
foreach my $key(sort keys %hash){
	print OT "$key\t";
	for (my $j=0;$j<=$#sample;$j++){
		if(exists $hash{$key}{$sample[$j]}){print OT "$hash{$key}{$sample[$j]}\t";}
		else {print OT "\t"}
			}
	print OT "\n";
	}
	
my $w="\t"x8;
print OT "\n\nQC matrix:\n";
print OT "$w\t";
for(my $i=0;$i<=$#sample;$i++){print OT "\t$sample[$i]";}print OT "\n";
foreach my $key (@tl){
	print OT "$w\t$key\t";
	for (my $j=0;$j<=$#sample;$j++){
		if(exists $qc{$key}{$sample[$j]}){print OT "$qc{$key}{$sample[$j]}\t";}
		else {print OT "\t"}
	}print OT "\n";
}
close OT;

