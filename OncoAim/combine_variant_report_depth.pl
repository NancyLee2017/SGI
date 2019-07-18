#!/usr/bin/perl -w
use strict;

die "perl $0 <in.variant.report.txt.list> <out.stat.xls> <AF,eg:0.05> <PGM | miseq>\n" unless (@ARGV ==4);

open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

my (@sample,@date,@st);
my (%hash,%qc);
while(<IN>){
	chomp;
	my $report=$_;
	my @tmp=split/\//,$_;
	my $file=$tmp[-1];$file=~s/\_variant\_report.txt//; push @sample,$file; push @date,$tmp[-2];
	my $libID=(split(/_/,$file))[0];
	my $workspace_name="$libID"."*";
	my $workspace_path;
	if ($ARGV[3]=~/pgm|PGM/) {$workspace_path=`find /OncoAim_PGM_denovo/workspace/ -type d -name "$workspace_name"`;}
	elsif ($ARGV[3]=~/miseq|MISEQ/) {$workspace_path=`find /OncoAim_denovo/workspace/ -type d -name "$workspace_name"`;}
	else {print "Please select sequencing plate!";}
	chomp $workspace_path;
	my $allele_counts_name;
	if ($ARGV[3]=~/pgm|PGM/) {$allele_counts_name="TSVC_variants.report.txt";}
	elsif ($ARGV[3]=~/miseq|MISEQ/){$allele_counts_name="variants.report.txt";}
	my $allele_counts=`find $workspace_path -name "$allele_counts_name"`;
	chomp $allele_counts;
#	print "allele_count_file is $allele_counts\n";	
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
			my $var_cov=1000;
			my $pos_num=(split(/:/,$pos))[1];
			my $k=join "\t",$gene,$pos,$ref,$var;
			my $o=join "\t",@a;
			if($freq>=$ARGV[2]){
				open COUNT, "$allele_counts"or die "Open $allele_counts error!!\n";
				while (<COUNT>){
					chomp;
					if(/$pos_num/){
						my @temp=split/\t/;
						$var_cov=$temp[4];
						$o=join "\t",$o,$var_cov;
					}
					else{next;}
				}close COUNT;
				$hash{$file}{$k}=$o;}
			else{next;}
		}
		elsif($_=~/Median RD\| Uniformity/){
			my $tt=<TXT>;
			my $qc=<TXT>;chomp($qc);$qc=~s/\s+//g; my @t=split/\|/,$qc;shift @t;my $p=join "\t",@t; 
			$qc{$file}=$p;
		}
	}
	close TXT;
}
close IN;

print OT "SeqDate\tLibraryID";for(my $i=0;$i<=$#st;$i++){print OT "\t$st[$i]";}print OT "\tVar_Depth\n";
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
