#!/usr/bin/perl -w
use strict;

die "perl $0 <in.variant.report.txt.list> <out.stat.xls> <AF,eg:0.05>\n" unless (@ARGV ==3);

open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
#open VR,"$ARGV[1]" or die "$ARGV[1] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

my (@var,@sample,@st,@qctt);
my (%hash,%qc);
while(<IN>){
	chomp;
	my $report=$_;
	my $file=(split/\//,$_)[-1];$file=~s/\_variant\_report.txt//; $file=join "=",$file,$report;push @sample,$file;
#	my $sampleid=(split/\_/,$file)[1];
	open TXT,"$report" or die "$report error!!\n";
	while(<TXT>){
		chomp;
		if($_=~/Gene\sSymbol\|/){@st=split/\|/;}
		elsif($_=~/\*\*\w+\*\*\|/){
#			$fusion++;
			my @a=split/\|/;
			my $gene=shift @a; my $pos=shift @a; my $ref=shift @a; my $var=shift @a; my $freq=shift @a;
			$gene=~s/\*//g;
			$pos=~s/\s+//g;
			my $k=join "\t",$gene,$pos,$ref,$var,@a;
			if($freq>=$ARGV[2]){
				$hash{$k}{$file}=$freq;}
			else{next;}
		}elsif($_=~/Median RD\| Uniformity/){
                        chomp;
                        @qctt=split/\|/,$_;
                        my $tt=<TXT>;
                        my $qc=<TXT>;chomp($qc);$qc=~s/\s+//g; my @t=split/\|/,$qc;
                        for(my $i=0;$i<=$#qctt;$i++){
                                $qc{$qctt[$i]}{$file}=$t[$i];
                        }
                }
	}
	close TXT;
}
close IN;

print OT "GeneSymbol\tPosition\tRef\tVariant\tLocusName\tcDNAChange\tCodonChange\tMutationType\tSomaticStatus\tPMID\t";for(my $i=0;$i<=$#sample;$i++){print OT "$sample[$i]\t";}print OT "\n";
#for(my $i=0;$i<=$#st;$i++){print OT "\t$st[$i]";}print OT "\n";
foreach my $k(sort keys %hash){
	print OT "$k\t";
	for(my $j=0;$j<=$#sample;$j++){
		if(exists $hash{$k}{$sample[$j]}){print OT "$hash{$k}{$sample[$j]}\t";}
		else{print OT "NA\t";}
	}
	print OT "\n";
}
for(my $i=0;$i<=$#qctt;$i++){
        print OT "$qctt[$i]","\t"x10;
        for(my $j=0;$j<=$#sample;$j++){
                if(exists $qc{$qctt[$i]}{$sample[$j]}){print OT "$qc{$qctt[$i]}{$sample[$j]}\t";}
                else{print OT "\t";}
        }
        print OT "\n";
}
#else{print OT "$sample[$i]\tNo_Variants_were_identified\n";}

close OT;
