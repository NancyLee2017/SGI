#!/usr/bin/perl -w
use strict;

die "perl $0 <in.need_primer.posi>  <out.primer.xls> <OncoAimDNA || BRCAim>\n\t\tin.need_primer.posi file format:\tchr1:123456\n" unless (@ARGV ==3);

open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";
print OT "Position\tchromosome\tchr_start\tchr_end\tgeneID\tIon_AmpliSeq_Fwd_Primer\tIon_AmpliSeq_Rev_Primer\n";

my %hash; my $pfile;
if($ARGV[2] eq "OncoAimDNA"){ $pfile="/home/hongyanli/my_file/asssay_info/assay_files/OncoAimV1.2_zuyu/IAD84338_OncoAimV1_version2_primer.txt";}
else{ $pfile="/home/hongyanli/my_file/asssay_info/assay_files/BRCAimV3_version5/BRCAimV3_Panel_20170515_primers.txt";}

open PF,"$pfile" or die "no $pfile!\n";
while(<PF>){
        chomp; #print "$_\n";
        my @a=split/\s+/,$_;
        my $k=join "\t",@a; #print "$k\n";
        $hash{$k}=1;
}
close PF;

while(<IN>){
	chomp;
	my @b=split/\s+/,$_;
	my @a=split/\:|\_|\-/,$b[0];$a[0]=~s/^\s+//;$a[1]=~s/^\s+//;
	my $chr=$a[0]; my $pos=$a[1];
#print "$chr\t$pos\n";
	foreach my $k(sort keys %hash){
		my @t=split/\t/,$k;
#print "$k\n$t[0]\t$t[1]\t$t[2]\n";
		if(($chr eq $t[0]) &&($t[1]<=$pos) &&($pos<=$t[2])){
			print OT "$_\t$k\n";
		}else{print "$_ not in panel!\n";}
	}
}
close IN;
close OT;
