#!/usr/bin/perl -w
¯
die "perl $0 <report.tsv.list> <var.filter.xls>\n" unless (@ARGV ==2);
open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";
my (%hash,%posi);
#my $filtAF=$ARGV[2];
my @sampleIDs;

while(<IN>)
{
	chomp;
	my @tem=split/\//,$_;
	my $libID=$tem[-2];
	push @sampleIDs,$libID;
	open TSV,"$_" or die "open $_ error!\n"; 
#	my ($m,$n)=(0,0);
	while(<TSV>)
	{
		chomp;
		next if($_=~/^Chromosome/);
		my @a=split/\t/;
		for(my $i=0;$i<=$#a;$i++){$a[$i]=~s/^\s+//;}
		$a[6]=sprintf "%.4f",$a[6];
		my $pos=join ":",$a[0],$a[1];$pos=~s/^\s+//;
		my $k=join "\t",$a[14],$pos,$a[2],$a[3],$a[4],$a[5],$a[12],$a[20],$a[26],$a[27],$a[29];
		my $o;
		if($a[8]=~/PASS/)
		{
			$o=$a[6];
		}
		else
		{
			$o=$a[6]."|".$a[8];
		}
			
		$hash{$libID}{$k}=$o;
		$posi{$k}+=1;
	}
	close TSV;
}
print OT "Gene\tLocus\tReference\tAlternate\ttype\tGenotype\tConsequence\tExonID\tProtein_position\tAmino_acids\tExisting_variation\t";
for(my $i=0;$i<=$#sampleIDs;$i++){print OT "$sampleIDs[$i]\t";}print OT "\n";
foreach my $k(sort keys %posi){
	print OT "$k\t";
	for(my $i=0;$i<=$#sampleIDs;$i++){
		if(exists $hash{$sampleIDs[$i]}{$k}){print OT "$hash{$sampleIDs[$i]}{$k}\t";}
		else{print OT " \t";}
	}
	print OT "\n";
}close OT;
