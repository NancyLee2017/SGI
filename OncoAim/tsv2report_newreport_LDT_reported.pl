#!/usr/bin/perl
use strict;

die "perl $0 <in.report.extra.clinsig.tsv.list> <out.matrix.xls>\n" unless (@ARGV ==2);
#The input list should be a list of *.report.extra.clinsig.tsv, which is under the folder "/OncoAim_denovo/new_report/"
open IN,"$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT,">$ARGV[1]" or die "Error! Cannot open $ARGV[1] \n";

#my @sample;
my %hash;

print OT "SampleID\tGeneName\tPosition\tExon\tRef\tVar\tFrequency\tLocusName\tcDNA_change\tProtein_change\tVarType\n";

while(<IN>){
	chomp;
	my $path=$_;
	my @a=split/\//;
	my @b=split/_/,$a[-2];
	my $sampleID=shift @b;
	my $file=join "=",$sampleID,$path;
#	push @sample,$file;
	open FILE1,"$_" or die "Error! Cannot open $_\n";
	while(<FILE1>){
		next if (/^Gene/);
		chomp;
		my @c=split/\t/;
#		next if ($c[6]<$ARGV[2]);
		next if ($c[1]=~/^PGKB/);
		my $position=$c[2].":".$c[3];
		my $gene=$c[0];
#		$c[20]=~s/\/.+//;
		my $exon=$c[17];
		my $ref=$c[4];
		my $var=$c[5];
		my $freq=$c[12];
#		my $depth=$c[7];
#		$c[22]=~s/ENST.+:c/c/;
		my $cDNA=$c[13];
#		if ($c[23]=~/ENSP.*\(p\.=\)/){$c[23]='(=)';}
#		elsif ($c[23]=~/ENSP.+:p\./){$c[23]=~s/ENSP.+:p/p/;}
		my $pro=$c[14];
		my $locus=$c[10];
#		if ($c[29]=~/(COSM\d+)/){
#			$locus=$1;}
#		else {my $locus=$c[29]}
		my $var_type=$c[6];
#		if ($c[10]=~){
		$hash{$sampleID}{$position}=join "\t",$sampleID,$gene,$position,$exon,$ref,$var,$freq,$locus,$cDNA,$pro,$var_type,$path;
			print OT "$hash{$sampleID}{$position}\n";
#		}
	}
	close FILE1;
}
close IN;

#print OT "SeqDate\tLibraryID";for(my $i=0;$i<=$#st;$i++){print OT "\t$st[$i]";}print OT "\n";
#for(my $i=0;$i<=$#sample;$i++){
#	if(exists $hash{$sample[$i]}){
#		foreach my $sk(sort keys %{$hash{$sample[$i]}}){
#			print OT "$date[$i]\t$sample[$i]\t";
#			if(exists $hash{$sample[$i]}{$sk}){print OT "$sk\t$hash{$sample[$i]}{$sk}\n";}
#			else{print OT "NA\n";}
#		}
#	}else{print OT "$date[$i]\t$sample[$i]\tNo_Variants_were_identified\n";}
#}
#print OT "SeqDate\tLibraryID\tTotalReads\tMappedReads\tMappingRates\tOnTargetReads\tOnTargetRate\tMedianRD\tUniformity\n";
#for(my $i=0;$i<=$#sample;$i++){
#	print OT "$date[$i]\t$sample[$i]\t$qc{$sample[$i]}\n";
#}
#close OT;
