#!/usr/bin/perl -w
use strict;
#原始数据上传路径为/mnt/rawdata/,bcl2fastq命令行修改
die "perl $0 <sequencer_dir> <out demultiplex.sh> \n" unless (@ARGV ==2);

open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

my $dir=$ARGV[0];
my ($dir_run,$dir_seq);
my @t=split/\//,$dir;
$dir_run=$t[4];
if ($t[3]=~/NextSeq500-1/){$dir_seq='/data/SeqStore/nextseq_01/';}
elsif ($t[3]=~/NextSeq500-2/){$dir_seq='/data/SeqStore/nextseq_02/';}
elsif ($t[3]=~/NextSeq500-3/){$dir_seq='/data/SeqStore/nextseq_03/';}
my $out_dir="$dir_seq"."$dir_run";
#print "$out_dir\n";
if (! -d $out_dir){print "Warning:$out_dir not exist!"; exit;}
my $csv_list=`ls $out_dir/*.csv`;chomp($csv_list);my @csv_list=split/\n/,$csv_list;
my %hash;
for(my $i=0;$i<=$#csv_list;$i++){
	open IN,"$csv_list[$i]" or die "Open $csv_list[$i] error!\n";
	my $judge_index_line="";
	while(<IN>){
		chomp;
		next if($_=~/,,,,,,,,/);
		if($_=~/Sample_ID/){
			$judge_index_line=<IN>;
			chomp($judge_index_line);
#			print "$judge_index_line\n";
		}
	}close IN;
	if( $judge_index_line=~/,,,D\d+,[A-Z]{8},\d+N,N{12},,/ || $judge_index_line=~/,,,D\d+,[A-Z]{8},,,,/){ `sed -i 's/NNN//g' $csv_list[$i]`; $hash{I8UMI12}=$csv_list[$i];}
        elsif($judge_index_line=~/,,,D\d+,[ATCG]{8}N{9},I\d+,[ATCG]{8},,/){`sed -i 's/NNN//g' $csv_list[$i]`;$hash{I8UMI9I8}=$csv_list[$i];}
	elsif($judge_index_line=~/,,,D\d+,[A-Z]{8},D\d+,[A-Z]{8},,/){$hash{I8I8}=$csv_list[$i];}
        elsif($judge_index_line=~/,,,SGIr53\sIndex\s\d+,[A-Z]{6},,,,/){$hash{I6I0}=$csv_list[$i];}
        else{
		my @content=split/\,/,$judge_index_line;
		my $len1=length($content[-5]);
		my $len2=length($content[-3]);
		my $k="Index1".$len1."Index2".$len2;
		$hash{$k}=$csv_list[$i];
	}
}
my $index2_length_xml=0;
open IN,"$dir/RunInfo.xml" or die "RunInfo.xml error!\n";
while(<IN>){
	chomp;
	if($_=~/Read Number=\"2\"/){$index2_length_xml=(split/\"/,$_)[3];}
	}
close IN;
print OT "#!/bin/sh\n";
foreach my $k(sort keys %hash){
	if($k eq "I6I0"){
		print OT "bcl2fastq -R $dir --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --create-fastq-for-index-reads --no-lane-splitting --sample-sheet $hash{I6I0} -o $out_dir  --barcode-mismatches 0 1>>$out_dir/$ARGV[1].o 2>>$out_dir/$ARGV[1].e\n";
	}
	elsif($k eq "I8I8"){
		print OT "bcl2fastq -R $dir --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --create-fastq-for-index-reads --no-lane-splitting --sample-sheet $hash{I8I8} -o $out_dir 1>>$out_dir/$ARGV[1].o 2>>$out_dir/$ARGV[1].e\n";
	}
	elsif($k eq "I8UMI12"){
		my $n=$index2_length_xml-8; print "I8UMI12 n= $n\n";
		print OT "cp $dir/RunInfo.xml $out_dir/RunInfo.xml.ori\n";
		if($n==0){
			print OT qq#perl -ne 'chomp;if(\$_=~/Read Number="3" NumCycles="12" IsIndexedRead="Y"/){\$_=~s/IsIndexedRead="Y"/IsIndexedRead="N"/;print "\$_\\n";}else{print "\$_\\n"}' $out_dir/RunInfo.xml.ori >$out_dir/RunInfo.xml#;print OT "\n";
			print OT "bcl2fastq -R $out_dir -i $dir/Data/Intensities/BaseCalls/ --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --create-fastq-for-index-reads --no-lane-splitting --sample-sheet $hash{I8UMI12} -o $out_dir 1>>$out_dir/$ARGV[1].o 2>>$out_dir/$ARGV[1].e\n";}
		else {print OT "bcl2fastq -R $dir --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --create-fastq-for-index-reads --no-lane-splitting --sample-sheet $hash{I8UMI12} --use-bases-mask Y*,I8n$n,Y12,Y* -o $out_dir 1>>$ARGV[1].o 2>>$ARGV[1].e\n";}
	}
	elsif($k eq "I8UMI9I8"){
		print OT "bcl2fastq -R $dir --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --create-fastq-for-index-reads --no-lane-splitting --sample-sheet $hash{I8UMI9I8} --use-bases-mask Y*,I8Y9,I8n4,Y* -o $out_dir 1>>$ARGV[1].o 2>>$ARGV[1].e\n";}
	else{
		print OT "bcl2fastq -R $dir --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --create-fastq-for-index-reads --no-lane-splitting --sample-sheet $hash{$k} -o $out_dir 1>>$out_dir/$ARGV[1].o 2>>$out_dir/$ARGV[1].e\n";
	}
}
close OT;
