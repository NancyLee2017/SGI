#!/usr/bin/perl -w
#use strict;
die "perl $0 <in.all.tsv.list> <out.compare.xls>\n" unless (@ARGV ==2);
open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

my (%hash,%posi);
my @sampleIDs;

while(<IN>)
{
	chomp;
	my $report=$_;
	my $libID=(split/\//,$_)[-2]; 
	push @sampleIDs,$libID;
	open TSV,"$report" or die "Open $report error!\n";

	while(<TSV>)
	{
		chomp;
		next if($_=~/^Chromosome/);
		next if
		my @a=split/\t/;
		for(my $i=0;$i<=$#a;$i++){$a[$i]=~s/^\s+//;}
		if($a[8]!~/PASS/){next;}
#		{
			$a[6]=sprintf "%.4f",$a[6];
			my $pos=join ":",$a[0],$a[1];
#			$pos=~s/^\s+//;
			if ($a[23]=~/EN.*\(p\.=\)/){$a[23]='(=)';}
			elsif ($a[23]=~/EN.*p\./){$a[23]=~s/EN.*p\.//;}
			$a[22]=~s/EN.+://;
			my $k=join "\t",$a[14],$pos,$a[2],$a[3],$a[4],$a[5],$a[19],$a[20],$a[21],$a[22],$a[23],$a[29],$a[44];
			my $o=join "|",$a[7],$a[6];
#		if($a[8]=~/PASS/)
#		{
#			$o=join "|",$a[7],$a[6];
#		}
#		else
#		{
#			$o=$a[6];
#		}
		$hash{$libID}{$k}=$o;
		$posi{$k}+=1;
		}
	
	close TSV;
}

print OT "Gene\tPosition\tRef\tAlt\tVariant_type\tGenotype\tLocation\tExon\tIntron\tcDNA_change\tAA_change\tExisting_variation\tClin_sig\t";
for(my $i=0;$i<=$#sampleIDs;$i++){print OT "$sampleIDs[$i]\t";}print OT "\n";
foreach my $k(sort keys %posi){
	print OT "$k\t";
	for(my $i=0;$i<=$#sampleIDs;$i++){
		if(exists $hash{$sampleIDs[$i]}{$k}){print OT "$hash{$sampleIDs[$i]}{$k}\t";}
		else{print OT " \t";}
	}
	print OT "\n";
}close OT;
