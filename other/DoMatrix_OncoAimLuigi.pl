#!/usr/bin/perl -w
#use strict;
die "Usage: perl $0 <report.tsv.list> <out.matrix.xls>\n" unless (@ARGV ==2);
open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

my (%hash,%posi);
my @sampleIDs;

while(<IN>)
{
	chomp;
	my $tsv=$_;
#	my $file=(split/\//,$_)[-2];
	my $libID=(split/\//,$tsv)[-2]; 
#	my @file=split/\=/,$_;
	push @sampleIDs,$libID;
	open TSV,"$tsv" or die "Open $tsv error!\n"; 
#	my ($m,$n)=(0,0);
	while(<TSV>)
	{
		chomp;
		next if($_=~/^Chromosome/);
		my @a=split/\t/;
		for(my $i=0;$i<=$#a;$i++){$a[$i]=~s/^\s+//;}
		if ($a[23]=~/EN.*\(p\.=\)/){$a[23]='(=)';}
		elsif ($a[23]=~/EN.*p\./){$a[23]=~s/EN.*p\.//;}
		$a[6]=sprintf "%.4f",$a[6];
		my $pos=join ":",$a[0],$a[1];
		my $k=join "\t",$a[14],$pos,$a[20],$a[5],$a[2],$a[3],$a[23],$a[4],$a[12];
		my $o=$a[6];
		if($a[8]=~/PASS/)
		{
			$o=join "|", $a[6],$a[7];
			$hash{$libID}{$k}=$o;
			$posi{$k}+=1;
		}
		else
		{
			$o=join "|", $a[6],$a[8];
		}
#		$hash{$libID}{$k}=$o;
#		$posi{$k}+=1;
	}
	close TSV;
}

print OT "Gene\tLocus\tExon\tGenotype\tRef\tAlt\tAA_change\tType\tConsequence\t";

for(my $i=0;$i<=$#sampleIDs;$i++){print OT "$sampleIDs[$i]\t";}print OT "\n";

foreach my $k(sort keys %posi){
	print OT "$k\t";
	for(my $i=0;$i<=$#sampleIDs;$i++){
		if(exists $hash{$sampleIDs[$i]}{$k}){print OT "$hash{$sampleIDs[$i]}{$k}\t";}
		else{print OT " \t";}
	}
	print OT "\n";
}close OT;
