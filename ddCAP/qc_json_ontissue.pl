#!/usr/bin/perl -w

use strict;
die "Usage: perl $0 <sqm.json.list> <qc.out.xls>\n" unless (@ARGV ==2);
open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";
my %qc;
print OT "SampleID\tRun_folder\tTotal_read\tMapped_read\tMapped_rate\tOntarget_read\tOntarget_rate\tUniformity\tAverage_coverage\tFraction_target_covered\tFraction_known_sites_covered\n";
while(<IN>){
	chomp;
	my @a=split/\//;
	$a[-1]=~s/\.sqm\.dedup\.json//;$a[-1]=~s/\.sqm\.json//;
	my $sampleID=$a[-1];
	my @temp=@a;pop @temp;
	my $folder=join "/",@temp;
	(open JSON,"$_" ) || (print "ERROR: Cannot open $_ !\n");
	while(<JSON>){
		$_=~s/\"//g;
		$_=~s/\}//g;
		$_=~s/\{//g;
		my @b=split/,/;
		for (my $i=0;$i<=$#b;$i++){
			if ($b[$i]=~/.+:\s\d+/){
				$b[$i]=~s/\s//g;
				my @c=split/:/,$b[$i];
				if ($c[0]!~/chr/){$c[1]=sprintf "%.3f", $c[1];}
				$qc{$c[0]}=$c[1];
			}
		}
		my $map_rate=$qc{mapped_read_count}/$qc{total_read_count}; $map_rate=sprintf "%.3f",$map_rate;
		my $tar_rate=$qc{ontarget_read_count}/$qc{mapped_read_count}; $tar_rate=sprintf "%.3f",$tar_rate;

		print OT "$sampleID\t$folder\t$qc{total_read_count}\t$qc{mapped_read_count}\t$map_rate\t$qc{ontarget_read_count}\t$tar_rate\t$qc{uniformity}\t$qc{average_coverage}\t$qc{fraction_target_covered}\t$qc{fraction_known_sites_covered}\n";
	}
}
