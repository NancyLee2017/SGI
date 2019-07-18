#!/usr/bin/perl
use strict;
die "perl $0 <in.report.extra.clinsig.tsv.list> <out.matrix.xls>\n" unless (@ARGV ==2);
#The input list should be a list of *.report.extra.clinsig.tsv "
open IN,"$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT,">$ARGV[1]" or die "Error! Cannot open $ARGV[1] \n";

my @sample;
my @tl=('Total_read','Mapped_read','Mapped_rate','Ontarget_read','Ontarget_rate','Average_amplicon_coverage','Uniformity');
my (%hash,%qc);

while(<IN>){
	chomp;
	my ($path,$report,$json)=($_,$_,$_);
	$report=~s/report.extra.clinsig.tsv/report.extra.tsv/;
	$json=~s/report.extra.clinsig.tsv/sqm.json/;
	my @a=split/\//;
	my @b=split/_/,$a[-2];
	my $sampleID=shift @b;
	my $file=join "=",$sampleID,$path;
	push @sample,$file;
	
	open FILE1,"$_" or die "Error! Cannot open $_\n";
	while(<FILE1>){
		next if (/^Gene/);
		chomp;
		my @c=split/\t/;
		my $maf=$c[12];
		my $section=$c[19];
#		next if ($maf<$ARGV[2]);
		next if ($section=~/PGKB/);
		my $position="chr".$c[2].":".$c[3];
		my $gene=$c[0];
		my $exon=$c[17];
		my $ref=$c[4];
		my $alt=$c[5];
		my $freq="$maf";
		my $cDNA=$c[13];
		my $pro=$c[14];
#		if ($pro=~/ENSP.*\(p\.=\)/){$pro='(=)';}
#		elsif ($pro=~/ENSP.+:p\./){$pro=~s/ENSP.+:p/p/;}
		my $locus=$c[10];
		my $var_type=$c[6];
		my $pos_var=join ":",$position,$ref,$alt;
		my ($transcript,$depth);
		
		open REPORT,"$report" or die "Error! Cannot open $report\n";
		while (<REPORT>){
			chomp;
			my @temp=split/\t/;
			my $pos=join ":",$temp[0],$temp[1],$temp[2],$temp[3];
			if ($pos eq $pos_var){
#				$depth=$temp[7];
				$transcript=$temp[36];
			}
			else{next;}
		}close REPORT;
		
		my $k=join "\t",$gene,$position,$exon,$ref,$alt,$locus,$cDNA,$pro,$transcript,$var_type;
#		$hash{$k}{$file}="$freq"."|"."$depth";
		$hash{$k}{$file}=$freq;
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

