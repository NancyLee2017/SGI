#!/usr/bin/perl -w

die "perl $0 <remove_cnv.IDlist> <workpath>\n eg:/home/hongyanli/workspace/CLS/ddCAPonTissus/180519_next02/\n" unless (@ARGV ==2);
open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";

my $path="$ARGV[1]";
if ($path!~/\/$/){$path="$path"."/";}
while(<IN>){
	chomp;
	my $ID=$_;
	my $sample_path="$path"."$ID"."/";
	my $cnv="$sample_path"."$ID".".cnv.tsv"; 
	my $ori="$cnv".".ori";
	my $cp_cnv=system("cp $cnv $ori");
	if ($cp_cnv!=0){print "cp $cnv error!\n";}
	open CNV,"$ori" or die "Error! Cannot open $ori\n";
	open OT, ">$cnv" or die "Error! Cannot open $cnv\n";
	while(<CNV>){
		chomp;
	#	my $raw_line=$_;
		my @t=split/\t/;
		if($t[3]>=4){
			print "Warning:$cnv has a CNV=$t[3]!!\n";
			print OT "$_\n";}
		else{next;}
	}close CNV;
	close OT;
}close IN;
