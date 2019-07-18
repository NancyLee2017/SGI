#!/usr/bin/perl -w

use strict;
die "Usage: perl $0 <id.list> <data_path> <sample_files.txt>\n" unless (@ARGV ==3);

open IN,"<$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[2]" or die "$ARGV[2] Error!\n";
my $data_folder=$ARGV[1];
my $work_folder=`pwd`;chomp $work_folder;
#chomp $data_folder;
if($data_folder=~/\/$/){chomp $data_folder;}

while(<IN>){
    chomp;
    my $r1=$data_folder."/".$_."*R1*.gz";
    my $r2=$data_folder."/".$_."*R2*.gz";
    my $path1=`ls -1 $r1`;chomp $path1;
    my $path2=`ls -1 $r2`;chomp $path2;
    my $info=$work_folder."/".$_.".tsv";
    print OT "$_\t$path1\t$path2\t$info\n";
}
