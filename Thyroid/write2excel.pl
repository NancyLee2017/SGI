#!/usr/bin/perl -w
#use strict;
die "perl $0 <variant.xls> <QCdup.xls> <QCdedup.xls> <combine_results.xls>\n" unless (@ARGV ==4);
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::FmtUnicode;
use Spreadsheet::WriteExcel;
use Unicode::Map;
use Encode;
use utf8;

open OT,">$ARGV[3]" or die "Error: Cannot creat  $ARGV[3]!\n";
my $workbook = Spreadsheet::WriteExcel->new($ARGV[3]) || (die "Error: Cannot creat excel workbook!");
my $worksheet1 = $workbook->add_worksheet("variant_matrix");

my $format1=$workbook->add_format();
$format1->set_bold();
$format1->set_border();
$format1->set_align('center');
my $format2=$workbook->add_format();
$format2->set_border();

open IN,"<$ARGV[0]" or die "Error: Cannot open $ARGV[0]!\n";
my $line_num=0;
while(<IN>){
	chomp;
	if (/read_counts_per_region/){next;}
	my @line=split/\t/;
	for (my $i=0;$i<=$#line;$i++){
		if($line_num==0){$worksheet1->write($line_num, $i, $line[$i], $format1 );}
		else{$worksheet1->write($line_num, $i, $line[$i], $format2);}
	}
	$line_num++;
}
close IN;

my $worksheet2 = $workbook->add_worksheet("QC_dup");
open IN2,"<$ARGV[1]" or die "Error: Cannot open $ARGV[1]!\n";
$line_num=0;
while(<IN2>){
        chomp;
        my @line=split;
        for (my $i=0;$i<=$#line;$i++){
        	if($line_num==0){$worksheet2->write($line_num, $i, $line[$i], $format1);}
               else{$worksheet2->write($line_num, $i, $line[$i], $format2);}
	}
        $line_num++;
}
close IN2;

my $worksheet3 = $workbook->add_worksheet("QC_dedup");
open IN3,"<$ARGV[2]" or die "Error: Cannot open $ARGV[2]!\n";
$line_num=0;
while(<IN3>){
        chomp;
        my @line=split;
        for (my $i=0;$i<=$#line;$i++){
        	if($line_num==0){$worksheet3->write($line_num, $i, $line[$i], $format1);}
               else{$worksheet3->write($line_num, $i, $line[$i], $format2);}
	}
        $line_num++;
}
close IN3;
close OT;
$workbook->close();
