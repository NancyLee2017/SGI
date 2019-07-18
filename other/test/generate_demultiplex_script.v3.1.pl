#!/usr/bin/perl -w
#crontab专用，勿动
use strict;

#die "perl $0 <sequencer_dir> <out demultiplex.sh> \n" unless (@ARGV ==2);

#open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";

my $dir=$ARGV[0];
my $csv_list=`ls $dir/*.csv`;chomp($csv_list);my @csv_list=split/\n/,$csv_list;
my %hash;
for(my $i=0;$i<=$#csv_list;$i++){
	open IN,"$csv_list[$i]" or die "$csv_list[$i] error!\n";
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
	if($judge_index_line=~/,,,D\d+,[A-Z]{8},,,,/){$hash{I8UMI}=$csv_list[$i];}
	elsif($judge_index_line=~/,,,,[A-Z]{8},,[A-Z]{8},,/){$hash{I8I8}=$csv_list[$i];}
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
print "#!/bin/sh\n";
print ". /etc/profile\n";
foreach my $k(sort keys %hash){
	if($k eq "I6I0"){
		print "/usr/local/bin/bcl2fastq -R $dir --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --create-fastq-for-index-reads --no-lane-splitting --sample-sheet $hash{I6I0} --barcode-mismatches 0 1>demultiplex.sh.o 2>demultiplex.sh.e\n";
	}
	elsif($k eq "I8I8"){
		print "/usr/local/bin/bcl2fastq -R $dir --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --create-fastq-for-index-reads --no-lane-splitting --sample-sheet $hash{I8I8} 1>>$ARGV[1].o 2>>$ARGV[1].e\n";
	}
	elsif($k eq "I8UMI"){
		print  "cp RunInfo.xml RunInfo.xml.ori\n";
		print  qq#perl -ne 'chomp;if(\$_=~/Read Number="3" NumCycles="12" IsIndexedRead="Y"/){\$_=~s/IsIndexedRead="Y"/IsIndexedRead="N"/;print "\$_\\n";}else{print "\$_\\n"}' RunInfo.xml.ori >RunInfo.xml#;print "\n";
		print "/usr/local/bin/bcl2fastq -R $dir --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --create-fastq-for-index-reads --no-lane-splitting --sample-sheet $hash{I8UMI} 1>>$ARGV[1].o 2>>$ARGV[1].e\n";}
	else{
		print "/usr/local/bin/bcl2fastq -R $dir --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --create-fastq-for-index-reads --no-lane-splitting --sample-sheet $hash{$k} 1>>$ARGV[1].o 2>>$ARGV[1].e\n";
	}
}
#close OT;
