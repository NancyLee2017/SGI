#!/usr/bin/perl -w
use strict;

die "perl $0 <site.list> <tsv.list> <checking_matrix.xls>\n site.list format: BRCA1\tchr17:41223094\tT\tC\n" unless (@ARGV ==3);

my (%site,%hash);
my @samples;

open IN,"$ARGV[0]" or die "Cannot open $ARGV[0]\n";
open OT,">$ARGV[2]" or die "Open $ARGV[2] error!\n";

while(<IN>){
	chomp;
	$_=~s/ //g;
	$site{$_}=1;
}
close IN;

open IN2,"$ARGV[1]" or die "Cannot open $ARGV[1]\n";
while(<IN2>){
	chomp;
	my @temp=split/=/;
	my $sampleID=$temp[0];
	push @samples,$sampleID;
	my $tsv=$temp[1];
	
	open IN3,"$tsv" or die "Cannot open $tsv\n";
	
	while(<IN3>){
		chomp;
		if(/Chromosome/){next;}
		else{
			my @a=split/\t/;
			my $pos=$a[0].":".$a[1];
			
			my $locus;
			if ($tsv=~/report.tsv/) {$locus=join "\t",$a[14],$pos,$a[2],$a[3];}#brca样本
			elsif($tsv=~/annot.tsv/){$locus=join "\t",$a[12],$pos,$a[2],$a[3];}#risk58样本
			elsif ($tsv=~/filtered.tsv/){$locus=join "\t",$a[14],$pos,$a[2],$a[3];print"ontissue\t$locus\n";}#ontissue样本
			foreach my $k (sort keys %site){
				if ($locus eq $k){$a[6]=sprintf "%.3f",$a[6]; $hash{$sampleID}{$k}=join "|",$a[6],$a[7],$a[8];print"1\n";}
				else{next;}
			}
		}
	}close IN3;
}close IN2;

	print OT "Gene\tPosition\tRef\tAlt\t";
	for( my $i=0;$i<=$#samples;$i++){print OT "$samples[$i]\t";}
	print OT "\n";
	
	foreach my $k (sort keys %site){
		print OT "$k\t";
		for( my $i=0;$i<=$#samples;$i++){
			if(exists $hash{$samples[$i]}{$k}){print OT "$hash{$samples[$i]}{$k}\t";}
			else {print OT "\t";}
		}print OT "\n";
	}
	




