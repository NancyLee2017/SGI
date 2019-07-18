#!/usr/bin/perl -w
use strict;
die "perl $0 <germline.tsv.list> <target.site.list> <generate_risk58_newreport.sh>\n" unless (@ARGV ==3);

open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open LIST, "$ARGV[1]" or die "Error! Cannot open $ARGV[1]\n";
open OT,">$ARGV[2]" or die "Error! Cannot open $ARGV[2]\n";

my $php='/media/pluto/Riskcare58_Software/Report_Generation/Riskcare58_Report_Process.php';
my %hash_target;

while(<LIST>){
	chomp;
	my @a=split/\:|\t/;
	my $k=join ":",$a[0],$a[1],$a[2],$a[3];
	$hash_target{$k}+=1;
#	print "$k\n";
}

while(<IN>){
	chomp;
	my ($raw_tsv,$new_tsv)=($_,$_);
	$new_tsv=~s/germline.tsv/germline.filted.tsv/;
	
	my $ori="$_".".ori";
	if(-e $ori){print "$ori exist!\n"}
	else{system("cp $_  $ori");}
	
	my @t=split/\//;
	my $tsv_name=pop @t;
	my $ID=(split/_/,$tsv_name)[0];
	my $workpath=join "/",@t;

	open TSV,"$_" or die "Error:Cannot open tsv file!\n";
	open TSV2,">$new_tsv" or die "Error:Cannot creat new tsv file!\n";
	while(<TSV>){
		chomp;
		if(/^Chromosome/){print TSV2 "$_\n";}
		else{
			my @t=split/\t/;
			if($t[12]!~/BRCA/){next;}#只要某一基因的结果
			else{
#				my $pos =join ":",$t[0],$t[1];
				my $key=join ":",$t[0],$t[1],$t[2],$t[3];
				if (exists $hash_target{$key}){my $line=join"\t",@t;print TSV2 "$line\n";}
			}
=pod
					if($t[8]=~/PASS/){print TSV2 "$_\n";}
					elsif($t[8]=~/^Blacklisted/)
					{
						print "Change $ID mutation $pos from $t[8] to PASS !\n";
						$t[8]='PASS';
						my $line=join"\t",@t;
						print TSV2 "$line\n";
					}
				}
			}
			else{next;}
=cut
		}
	}
	close TSV2; close TSV;
	
	system("rm $raw_tsv");
	system ("mv $new_tsv $raw_tsv");
	
	print OT "cd $workpath \n php $php $ID \n";
	
}
