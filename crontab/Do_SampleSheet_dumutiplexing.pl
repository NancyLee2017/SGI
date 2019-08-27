#!/usr/bin/perl -w
#根据sequencer.info区分不同index类型，并产生相应的csv文件

use strict;
use POSIX;
my $Experiment_Time=strftime("%Y%m%d",localtime());
#print "$Experiment_Time\n";
my $Date=strftime("%Y/%m/%d",localtime());
#print "$Date\n";

die "perl $0 <sequencer.info>\n" unless (@ARGV==1);

open IN, "$ARGV[0]" or die "Can't open sequencer.info \n";

sub header_print{
	print OT "[Header],,,,,,,,,\nIEMFileVersion,4,,,,,,,,\nInvestigator Name,Alan,,,,,,,,\n";
	print OT "Experiment Name,$Experiment_Time,,,,,,,,\nDate,$Date,,,,,,,,\n";
	print OT "Workflow,GenerateFASTQ,,,,,,,,\nApplication,FASTQ Only,,,,,,,,\nAssay,Truseq HT,,,,,,,,\nDescription,,,,,,,,,\nChemistry,Amplicon,,,,,,,,\n,,,,,,,,,\n";
	print OT "[Reads],,,,,,,,,\n148,,,,,,,,,\n148,,,,,,,,,\n,,,,,,,,,\n[Settings],,,,,,,,,\nReverseComplement,0,,,,,,,,\n,,,,,,,,,\n[Data],,,,,,,,,\n";
	print OT "Sample_ID,Sample_Name,Sample_Plate,Sample_Well,I7_Index_ID,index,I5_Index_ID,index2,Sample_Project,Description\n";
}

my (%hash_d8umi,%hash_d8d8,%hash_i6i0);
my (@D8UMI,@D8D8,@I6I0);

while(<IN>){
	chomp;
	my @a=split/\t/; 
#	print "$a[4]\n"; 测试语句
	if ($_=~/(D\d+)\t([A-Z]{8})\t(\d+N)\t(N{12})/){push @D8UMI,$a[2]; $hash_d8umi{$a[2]}=$a[2].','.$a[2].',,,'.$1.','.$2.','.$3.','.$4.',,';}
	elsif($_=~/(D\d+)\t([A-Z]{8})\t(D\d+)\t([A-Z]{8})/){push @D8D8,$a[2]; $hash_d8d8{$a[2]}=$a[2].','.$a[2].',,,'.$1.','.$2.','.$3.','.$4.',,';}
	elsif($_=~/(SGIr53\sIndex\s\d+)\t([A-Z]{6})/){push @I6I0,$a[2]; $hash_i6i0{$a[2]}=$a[2].','.$a[2].',,,'.$1.','.$2.',,,,';}
	else{print "ERROR: Cannot recognize index, please check input: $_\n"}
}close IN;

if (@D8UMI!=0){
	open OT,">SampleSheet-D8UMI.csv" or die "ERROR: Cannot creat SampleSheet-D8UMI.csv\n";
	header_print();
	for (my $i=0;$i<=$#D8UMI;$i++){
		print OT "$hash_d8umi{$D8UMI[$i]}\n";
	}close OT;
}
else{print "Notice: No SampleSheet-D8UMI.csv\n"}

if (@D8D8!=0){
        open OT,">SampleSheet-D8D8.csv" or die "ERROR:Cannot creat SampleSheet-D8D8.csv\n";
	header_print();
	for (my $i=0;$i<=$#D8D8;$i++){
		print OT "$hash_d8d8{$D8D8[$i]}\n";
        }close OT;
}
else{print "Notice: No SampleSheet-D8D8.csv\n"}

if (@I6I0!=0){
	open OT,">SampleSheet-I6I0.csv" or die "ERROR: Cannot creat SampleSheet-I6I0.csv\n";
	header_print();
	for (my $i=0;$i<=$#I6I0;$i++){
                print OT "$hash_i6i0{$I6I0[$i]}\n";
        }close OT;
}
else{print "Notice: No SampleSheet-I6I0.csv\n"}

