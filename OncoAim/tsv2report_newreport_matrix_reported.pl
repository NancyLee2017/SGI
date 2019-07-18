#!/usr/bin/perl
use strict;

die "perl $0 <in.report.extra.clinsig.tsv.list> <out.matrix.xls>\n" unless (@ARGV ==2);
#The input list should be a list of *.report.extra.clinsig.tsv, which is under the folder "/OncoAim_denovo/new_report/"
open IN,"$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT,">$ARGV[1]" or die "Error! Cannot open $ARGV[1] \n";

my (@sample);
my (%hash);

#print OT "SampleID\tGeneName\tPosition\tExon\tRef\tVar\tFrequency\tLocusName\tcDNA_change\tProtein_change\tVarType\tDepth\n";

while(<IN>){
	chomp;
	my $path=$_;
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
		my $source=$c[1];
#		next if ($maf<$ARGV[2]);
		next if ($source=~/PGKB/);
		my $position=$c[2].":".$c[3];
		my $gene=$c[0];
#		$c[17]=~s/\/.+//;
		my $exon=$c[17];
		my $ref=$c[4];
		my $alt=$c[5];
		my $freq="$maf";
#		my $depth=$c[7];
		$c[22]=~s/ENST.+:c/c/;
		my $cDNA=$c[13];
		my $pro=$c[14];
#		if ($pro=~/ENSP.*\(p\.=\)/){$pro='(=)';}
#		elsif ($pro=~/ENSP.+:p\./){$pro=~s/ENSP.+:p/p/;}
		my $locus=$c[10];
#		if ($c[29]=~/(COSM\d+)/){
#			$locus=$1;}
#		else {my $locus=$c[29]}
		my $var_type=$c[6];
#		if ($c[10]=~){
		my $k=join "\t",$gene,$position,$exon,$ref,$alt,$locus,$cDNA,$pro,$var_type;
		$hash{$k}{$file}=$freq;
		
#			print OT "$hash{$sampleID}{$position}\n";
#		}
	}
	close FILE1;
}
close IN;

print OT "GeneName\tPosition\tExon\tRef\tAlt\tLocusName\tcDNA_change\tProtein_change\tVarType";
for(my $i=0;$i<=$#sample;$i++){print OT "\t$sample[$i]";}print OT "\n";
foreach my $key(sort keys %hash){
	print OT "$key\t";
	for (my $j=0;$j<=$#sample;$j++){
		if(exists $hash{$key}{$sample[$j]}){print OT "$hash{$key}{$sample[$j]}\t";}
		else {print OT "NA\t"}
			}
	print OT "\n";
	}
close OT;

