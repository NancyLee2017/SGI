#!/usr/bin/perl -w
use strict;

die "perl $0 <in.fusion.report.txt.list>  <out.stat.xls> \n" unless (@ARGV ==2);

open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

my (@var,@sample,@date,@st);
my (%hash,%fusion);
while(<IN>){
	chomp;
	my $report=$_; 
	my ($sd,$fid)=(split/\//,$_)[-4,-2]; my $file="";
	if($fid=~/\-M\_/){my @fid=split/\_/,$fid;$file=join "_",$fid[0],$fid[1];}elsif($fid=~/\.IonXpress/){my @fid=split/\./,$fid;my $tt=(split/\_/,$fid[0])[0];$file=join ".",$tt,$fid[1];}else{$file=$fid;}
	push @sample,$file; push @date,$sd;
	open TXT,"$report" or die "$report error!!\n";
	my ($control,$fusion,$mapread,$maprate,$avgCPK)=(0,0,0,0,0);
	while(<TXT>){
		chomp;my @t=split/\t/,$_;
		if($_=~/Transcript/){@st=@t;}
		elsif($_=~/EXPR_CONTROL/){$control++;my $cpK=(split/\,/,$t[5])[0];$avgCPK+=$cpK;}
		elsif($_=~/Total_mapped_reads/){$mapread=(split/\,/,$t[-1])[0];}
		elsif($_=~/Mapping_rate/){$maprate=(split/\,/,$t[-1])[0];}
		elsif($_=~/Positive/){
				$fusion++; my $o="";#print "$file\t$t[0]\t$mapread\t$maprate\n";
				for(my $i=1;$i<=$#t;$i++){my @c=split/\,/,$t[$i];$o.="$c[0]\t";} $o=~s/\s+$//;
				#$hash{$file}{$t[0]}=$o;
				$fusion{$file}{$t[0]}=$o;
		}elsif($_=~/ASSAYS_5P_3P/){next;}else{next;}
	}$avgCPK/=5;
	if($mapread<50000 || $maprate<60 || $avgCPK<=500){
		my $tmp=join "\t","\t"x6,$mapread,$maprate;my $tsk="RUN FAILED DUE TO QC FAILURE";$hash{$file}{$tsk}=$tmp;
#		my $o=$hash{$file}{$sk};$o=join "\t","RUN FAILED DUE TO QC FAILURE","\t"x5,$mapread,$maprate;$hash{$file}{$sk}=$o;
	}
	elsif($control==0){
		if($fusion >0){foreach my $sk(keys %{$fusion{$file}}){my $o=$fusion{$file}{$sk};$o.="\tNoControl";$hash{$file}{$sk}=$o;}}
		else{my $tmp=join "\t","\t"x6,$mapread,$maprate;$hash{$file}{"NO FUSION DETECTED"}=$tmp;}
	}elsif($control>0){
		if($fusion >0){foreach my $sk(keys %{$fusion{$file}}){my $o=$fusion{$file}{$sk};$o=join "\t",$o,$mapread,$maprate;$hash{$file}{$sk}=$o;}}
		else{my $tmp=join "\t","\t"x6,$mapread,$maprate;$hash{$file}{"NO FUSION DETECTED"}=$tmp;}
	}
	close TXT;
}
close IN;

print OT "SeqDate\tSampleID";for(my $i=0;$i<=$#st;$i++){print OT "\t$st[$i]";}print OT "\tTotalMappedReads\tMappingRate\n";
for(my $i=0;$i<=$#sample;$i++){
	if(exists $hash{$sample[$i]}){
	foreach my $sk(sort keys %{$hash{$sample[$i]}}){
		print OT "$date[$i]\t$sample[$i]\t$sk\t";
		if(exists $hash{$sample[$i]}{$sk}){print OT "$hash{$sample[$i]}{$sk}\n";}
		else{print OT "NA\n";}
		}
	}else{print OT "$date[$i]\t$sample[$i]\tNA:RUN FAILED DUE TO QC FAILURE\n";}
}
close OT;
