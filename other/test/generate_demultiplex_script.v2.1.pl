#!/usr/bin/perl -w
#crontab专用，勿动
use strict;

my $dir=$ARGV[0];
my ($dir_run,$dir_seq);
my @t=split/\//,$dir;
$dir_run=$t[4];
if ($t[3]=~/NextSeq500-1/){$dir_seq='/data/SeqStore/nextseq_01/';}
elsif ($t[3]=~/NextSeq500-2/){$dir_seq='/data/SeqStore/nextseq_02/';}
elsif ($t[3]=~/NextSeq500-3/){$dir_seq='/data/SeqStore/nextseq_03/';}
my $out_dir="$dir_seq"."$dir_run";

my $csv_list=`ls $out_dir/*.csv`;chomp($csv_list);my @csv_list=split/\n/,$csv_list;
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
	elsif($judge_index_line=~/,,,D\d+,[A-Z]{8},\d+N,N{12},,/){ `sed -i 's/NNN//g' $csv_list[$i]`; $hash{I8UMI}=$csv_list[$i];}
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
		print "/usr/local/bin/bcl2fastq -R $dir --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --create-fastq-for-index-reads --no-lane-splitting --sample-sheet $hash{I6I0} -o $out_dir --barcode-mismatches 0 1>demultiplex.sh.o 2>demultiplex.sh.e\n";
	}
	elsif($k eq "I8I8"){
		print "/usr/local/bin/bcl2fastq -R $dir --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --create-fastq-for-index-reads --no-lane-splitting -o $out_dir --sample-sheet $hash{I8I8} 1>>demultiplex.sh.o 2>>demultiplex.sh.e\n";
	}
	elsif($k eq "I8UMI"){
		print  "cp $dir/RunInfo.xml $out_dir/RunInfo.xml.ori\n";
		print  qq#perl -ne 'chomp;if(\$_=~/Read Number="3" NumCycles="12" IsIndexedRead="Y"/){\$_=~s/IsIndexedRead="Y"/IsIndexedRead="N"/;print "\$_\\n";}else{print "\$_\\n"}' $out_dir/RunInfo.xml.ori >$out_dir/RunInfo.xml#;print "\n";
		print "/usr/local/bin/bcl2fastq -R $out_dir -i $dir/Data/Intensities/BaseCalls/ --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --create-fastq-for-index-reads --no-lane-splitting -o $out_dir --sample-sheet $hash{I8UMI} 1>>demultiplex.sh.o 2>>demultiplex.sh.e\n";}
	else{
		print "/usr/local/bin/bcl2fastq -R $dir --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --create-fastq-for-index-reads --no-lane-splitting -o $out_dir --sample-sheet $hash{$k} 1>>demultiplex.sh.o 2>>demultiplex.sh.e\n";
	}
}
#close OT;
