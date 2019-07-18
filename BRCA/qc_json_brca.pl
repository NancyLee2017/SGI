#!/usr/bin/perl -w

use strict;
die "Usage: perl $0 <sqm.json.list> <qc.out.xls>\n" unless (@ARGV ==2);
open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

my (%qc,%ampli_loc,%ampli_cov);
my @samples;
print OT "SampleID\tTotal_read\tMapped_read\tMapped_rate\tOntarget_read\tOntarget_rate\tAverage_amplicon_coverage\tKnown_sites_coverd\tUniformity\n";
while(<IN>){
	chomp;
	my @a=split/\//;
	my $sampleID=(split/_/,$a[-2])[1];
	push @samples, $sampleID;
	open JSON,"$_" or die "Cannot open $_ !\n";
	while(<JSON>){
		$_=~s/\"//g;
		$_=~s/\}//g;
		$_=~s/\{//g;
		$_=~s/read_counts_per_region://;
		$_=~s/read_counts_per_amplicon://;
#		print "$sampleID\n";
		my ($total_read, $mapped_read, $on_target_read, $average_cover,$uniformity, $known_sites);
		my @b=split/,/;
		for (my $i=0;$i<=$#b;$i++){
			if($b[$i]=~/ontarget_read_count/){$on_target_read=$b[$i];$on_target_read=~s/.+:\s//;}
			elsif($b[$i]=~/total_read_count/){$total_read=$b[$i];$total_read=~s/.+:\s//;}
			elsif($b[$i]=~/average_amplicon_coverage/){$average_cover=$b[$i];$average_cover=~s/.+:\s//;}
			elsif($b[$i]=~/uniformity/){$uniformity=$b[$i];$uniformity=~s/.+:\s//;}
			elsif($b[$i]=~/fraction_known_sites_covered/){$known_sites=$b[$i];$known_sites=~s/.+:\s//;}
			elsif($b[$i]=~/mapped_read_count/){$mapped_read=$b[$i];$mapped_read=~s/.+:\s//;}
			elsif($b[$i]=~/chr/){
				$b[$i]=~s/\s//g;
				my @tem=split/:/,$b[$i];
				my $loc=$tem[0].":".$tem[1];
				$ampli_loc{$loc}=1;
				$ampli_cov{$sampleID}{$loc}=$tem[2];
#				print "$b[$i]\n";
			}
		}
		my $map_rate=$mapped_read/$total_read;
		$map_rate=sprintf "%.3f",$map_rate;
		my $tar_rate=$on_target_read/$mapped_read;
		$tar_rate=sprintf "%.3f",$tar_rate;
		$average_cover=sprintf "%.1f",$average_cover;
		$uniformity=sprintf "%.3f",$uniformity;
		my $k=join "\t",$total_read,$mapped_read,$map_rate,$on_target_read,$tar_rate,$average_cover,$known_sites,$uniformity;
		$qc{$sampleID}=$k;
		print OT "$sampleID\t$k\n";
	}
}

print OT "\n\nAmplicon_locus\t";
for (my $i=0;$i<=$#samples;$i++){
	print OT "$samples[$i]\t";
}
print OT "\n";

foreach my $k (sort keys %ampli_loc){
	print OT "$k\t";
	for (my $i=0;$i<=$#samples;$i++){
		if(exists $ampli_cov{$samples[$i]}{$k}){print OT "$ampli_cov{$samples[$i]}{$k}\t";}
		else{print OT "\t";}
	}
	print OT "\n";
}
