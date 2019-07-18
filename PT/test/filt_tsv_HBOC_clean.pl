#!/usr/bin/perl -w

die "perl $0 <tsv.list> <target_site.list>\ntarget_site format: chr13:32931912	A	G\n" unless (@ARGV ==2);
open IN,"$ARGV[0]" or die "$ARGV[0] open error!\n";
open IN2,"$ARGV[1]" or die "$ARGV[1] open error!\n";

my %hash;
while(<IN2>){
	chomp;
	my @t=split/\t|\s/;
	my $k=join"\t",@t;
#	print "$k\n";
	$hash{$k}=1;
}

while(<IN>){
	chomp;
	my @a=split/\//;
	my $libID=(split/_/,$a[-1])[0]; 
	my $new_tsv="$libID".".filtered.anno.clean.vcf";
	open TSV,"$_" or die "Open $_ tsv files error!\n";
	open OT, ">$new_tsv" or die "Creat $libID new vcf file error!\n";
	print OT "#chr\tstart\tend\tref\talt\tgene\ttranscript\tcHGVS\tpHGVS\tgenotype\tfrequency\n";
	while(<TSV>){
		chomp;
		#if (/^##(.+)command(.+)/i){next;}
		#elsif(/^##/){print OT "$_\n";}
		if (/^Chromosome/){next;}
		elsif (/chr/){
			my @b=split/\t/;
			my $pos=join ":",$b[0],$b[1];
			my $k=join "\t",$pos,$b[2],$b[3];
			if(exists $hash{$k}){
#				print"match\n";
				my $len=length($b[2]);
				my $end=$b[1]+$len-1;
				$b[20]=~s/ENST.+://;my $hgvsc=$b[20];
				$b[21]=~s/ENSP.+://;my $hgvsp=$b[21];
				my $trans=$b[34];
				my $geno;
				if ($b[6]>0.8){$geno="homo";}
				else{$geno="hete";}
				my $freq=sprintf("%.3f",$b[6]);
				my $show=join"\t",$b[0],$b[1],$end,$b[2],$b[3],$b[12],$trans,$hgvsc,$hgvsp,$geno,$freq;
				print OT "$show\n";
			}
			else{next;}
			
		} 
		
	}close OT;
}
close IN;
