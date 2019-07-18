#!/usr/bin/perl -w

die "perl $0 <vcf.list> <target_site.list>\ntarget_site format: chr13:32931912	A	G\n" unless (@ARGV ==2);
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
	my $new_vcf="$libID".".filtered.vcf";
	open VCF,"$_" or die "Open $_ vcf files error!\n";
	open OT, ">$new_vcf" or die "Creat $libID new vcf file error!\n";
	while(<VCF>){
		chomp;
		if (/^##(.+)command(.+)/i){next;}
		elsif(/##VEP|##FILTER|##contig/){next;}
		elsif(/^##/){print OT "$_\n";}
		elsif (/^#CHROM/){print OT "$_\n";}
		elsif (/chr/){
			my @b=split/\t/;
			my $pos=join ":",$b[0],$b[1];
			my $k=join "\t",$pos,$b[3],$b[4];
			if(exists $hash{$k}){;print OT "$_\n";}
			else{next;}
			
		} 
		
	}close OT;
}
close IN;
