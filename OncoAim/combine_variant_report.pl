#!/usr/bin/perl -w
use strict;

die "perl $0 <in.variant.report.txt.list>  <out.stat.xls> <AF,eg:0.05>\n" unless (@ARGV ==3);

open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

my (@var,@sample,@date,@st);
my (%hash,%qc);
while(<IN>){
	chomp;
	my $report=$_;my @tmp=split/\//,$_;
	my $file=$tmp[-1];$file=~s/\_variant\_report.txt//; push @sample,$file; push @date,$tmp[-2];
	open TXT,"$report" or die "$report error!!\n";
	while(<TXT>){
		chomp;
		if($_=~/Gene\sSymbol\|/){@st=split/\|/;}
		elsif($_=~/\*\*\w+\*\*\|/){
#			$fusion++;
			my @a=split/\|/;
			my $gene=shift @a; my $pos=shift @a; my $ref=shift @a; my $var=shift @a; my $freq=$a[0];
			$gene=~s/\*//g;
			$pos=~s/\s+//g;
			my $k=join "\t",$gene,$pos,$ref,$var;
			my $o=join "\t",@a;
			if($freq>=$ARGV[2]){
				$hash{$file}{$k}=$o;}
			else{next;}
		}elsif($_=~/Median RD\| Uniformity/){
			my $tt=<TXT>;
			my $qc=<TXT>;chomp($qc);$qc=~s/\s+//g; my @t=split/\|/,$qc;shift @t;my $p=join "\t",@t; 
			$qc{$file}=$p;
		}
	}
	close TXT;
}
close IN;

print OT "SeqDate\tLibraryID";for(my $i=0;$i<=$#st;$i++){print OT "\t$st[$i]";}print OT "\n";
for(my $i=0;$i<=$#sample;$i++){
	if(exists $hash{$sample[$i]}){
		foreach my $sk(sort keys %{$hash{$sample[$i]}}){
			print OT "$date[$i]\t$sample[$i]\t";
			if(exists $hash{$sample[$i]}{$sk}){print OT "$sk\t$hash{$sample[$i]}{$sk}\n";}
			else{print OT "NA\n";}
		}
	}else{print OT "$date[$i]\t$sample[$i]\tNo_Variants_were_identified\n";}
}
print OT "SeqDate\tLibraryID\tTotalReads\tMappedReads\tMappingRates\tOnTargetReads\tOnTargetRate\tMedianRD\tUniformity\n";
for(my $i=0;$i<=$#sample;$i++){
	print OT "$date[$i]\t$sample[$i]\t$qc{$sample[$i]}\n";
}
close OT;
