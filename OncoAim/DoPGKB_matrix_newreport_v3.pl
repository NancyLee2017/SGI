#!/usr/bin/perl
use strict;
die "perl $0 <in.report.extra.clinsig.tsv.list> <out.PGKB.xls> \n" unless (@ARGV ==2);
#The input list should be a list of *.report.extra.clinsig.tsv, which is under the folder "/OncoAim_denovo/new_report/"

open IN1,"$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
#open IN2,"$ARGV[1]" or die "Error! Cannot open $ARGV[1] Error!\n";
open OT,">$ARGV[1]" or die "Error! Cannot open $ARGV[1] Error!\n";

my %hash;

#print OT "SampleID\tGeneName\tLocusName\tPosition\tRef\tAlt\tGenotype\tPGKB_type\tcDNA_change\tProtein_change\tMAF\n";
print OT "SampleID\tGeneName\tLocusName\tPosition\tRef\tAlt\tGenotype\tPGKB_type\tcDNA_change\tProtein_change\n";
while (<IN1>){
	chomp;
	my @a=split/\//;
	my @b=split/_/,$a[-2];
	my $sampleID=shift @b;
	open FILE1,"$_";
	while(<FILE1>){
		next if (/Gene/);
#		if (/(PGKB_SNPs)/){
#		else{
		chomp;
		my @c=split/\t/;
		if ($c[1]=~/PGKB_SNPs/){
			my $position="chr".$c[2].":".$c[3];
			my $ref=$c[4];
			my $alt=$c[5];
			my $gene=$c[0];
			my $locus=$c[10];
			my $dna_change=join "/",$c[4],$c[5]; 
			my $PGKB_type=$c[9];
#			if ($c[23]=~/EN.*\(p\.=\)/){$c[23]='(=)';}
#			elsif ($c[23]=~/EN.*p\./){$c[23]=~s/EN.*p\.//;}
			my $cDNA_change=$c[13];
			my $AA_change=$c[15];
			my $genotype=$c[7];
			$c[12]=sprintf "%.2f",$c[12];
			my $maf=$c[12];
#			if ($PGKB_type=~/A\/A/){$genotype=join "/",$c[2],$c[2];}
#			elsif ($PGKB_type=~/A\/B/){$genotype=join "/",$c[2],$c[3];}
#			elsif ($PGKB_type=~/B\/B/){$genotype=join "/",$c[3],$c[3];}
#			else {$genotype=$PGKB_type}
#			my $AA_change=$c[11]=~s/p\.//;
#			$hash{$sampleID}{$position}=join "\t",$gene,$locus,$ref,$genotype,$PGKB_type,$dna_change,$AA_change,$maf;
#			print OT "$sampleID\t$gene\t$locus\t$position\t$ref\t$alt\t$genotype\t$PGKB_type\t$cDNA_change\t$AA_change\t$maf\n";
                        print OT "$sampleID\t$gene\t$locus\t$position\t$ref\t$alt\t$genotype\t$PGKB_type\t$cDNA_change\t$AA_change\n";
		}
	}
	close FILE1;
}
close IN1;
close OT;

