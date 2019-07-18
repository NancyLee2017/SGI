#!/usr/bin/perl -w
#增加QC步骤
use strict;

die "perl $0 <report.clinsig.tsv.list> <out.matrix.xls>\n" unless (@ARGV ==2);

open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";
open OT2,">json.list" or die "Creat json.list fail!\n";

my (%hash,%posi);
my @sampleIDs;

while(<IN>)
{
	chomp;
	my $tsv_path=$_;
	my $json_path=$_;
	$json_path=~s/report.clinsig.tsv/sqm.json/;
	print OT2 "$json_path\n";
	my @temp=split/\//;
	my @t=split(/_/,$temp[-2]);
	my $sampleID="$t[0]"."_"."$t[1]"."="."$tsv_path";
	push @sampleIDs,$sampleID;
	
	open TSV,"$tsv_path" or die "Cannot open $tsv_path !\n"; 
	while(<TSV>)
	{
		next if($_=~/^Chromosome/);
		chomp;
		my @a=split/\t/;
		for(my $i=0;$i<=$#a;$i++){$a[$i]=~s/^\s+//;}
		my $pos=join ":",$a[0],$a[1];
#		$pos=~s/chr//;
#		my $cosmic;
#		if ($a[29]=~/(COSM.+)\&/){$cosmic=$1;}
#		else{$cosmic=$a[29];}
		$a[6]=sprintf "%.3f",$a[6];
		$a[48]=~s/[0-9]-//;
		$a[12]=~s/\_variant//;
		$a[20]=~s/\/.+//;

		my $k=join "\t",$a[14],$pos,$a[20],$a[2],$a[3],$a[22],$a[23],$a[4],$a[12],$a[48];#不再输出Existing_variation列
		my $o;
		if($a[8]=~/PASS/)
		{
			$o=$a[6]."|".$a[7];
		}
		else
		{
			$o=$a[8];
		}
			
		$hash{$sampleID}{$k}=$o;
		$posi{$k}+=1;
	}
	close TSV;
}close OT2;

print OT "Gene\tLocus\tExon\tRef\tAlt\tHGVsc\tHGVsp\tType\tConsequence\tClin_sig\t";
for(my $i=0;$i<=$#sampleIDs;$i++){print OT "$sampleIDs[$i]\t";}print OT "\n";
foreach my $k(sort keys %posi){
	print OT "$k\t";
	for(my $i=0;$i<=$#sampleIDs;$i++){
		if(exists $hash{$sampleIDs[$i]}{$k}){print OT "$hash{$sampleIDs[$i]}{$k}\t";}
		else{print OT " \t";}
	}
	print OT "\n";
}close OT;

system ("perl /home/hongyanli/script/BRCA/qc_json_brca.pl json.list QC.xls");
