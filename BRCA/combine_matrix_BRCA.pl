#!/usr/bin/perl -w
use strict;

die "perl $0 <site.list> <raw_matrix.list> <combined_matrix.xls>\n" unless (@ARGV ==3);

my (%site,%hash);

open IN,"$ARGV[0]" or die "Cannot open $ARGV[0]\n";
open OT,">$ARGV[2]" or die "Open $ARGV[2] error!\n";

while(<IN>){
	chomp;
	$site{$_}=1;
}
close IN;

open IN2,"$ARGV[1]" or die "Cannot open $ARGV[1]\n";
while(<IN2>){#读入list
	chomp;
	open IN3,"$_" or die "Cannot open $_\n";
	my $length;
	my @samples;
	my %vars;
	while(<IN3>){#处理matrix
		chomp;
		if(/Gene/){
#			my @tl=split/\t/;
#			for (my $i=0;$i<=$#tl;$i++){
#				if (/tsv$/){push @samples, $tl[$i];}
#			}
			print OT "$_\t";
		}
		else{
			my @a=split/\t/;
			$length=$#a;
			my $key=join "\t", $a[0],$a[1],$a[3],$a[4];
			$vars{$key}=$_;
		}
	}close IN3;
	
	foreach my $k (sort keys %site){
		if(exists $vars{$k}){$hash{$k}=$hash{$k}.$vars{$k}."\t";}
		else {my $x=$length-4; my $fill="\t"x$x; $hash{$k}=$hash{$k}.$k."\t".$fill."\t";}
	}
	
}close IN2;

print OT "$_\n";

foreach my $k(sort keys %hash){
	print OT "$hash{$k}\n";
}

