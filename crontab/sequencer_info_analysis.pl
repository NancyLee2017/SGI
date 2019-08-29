#!/usr/bin/perl -w
#数据拆分后，根据sequencer.info，分别生成各流程用的samples_file,和id.list, 10gene_id.list
use strict;
use utf8;

die "perl $0 <CLS.seqinfo.xls> <working_dir> \n" unless (@ARGV==2);

my $dir=$ARGV[1];
#eg:/data/SeqStore/nextseq_03/190817_TPNB500270AR_0134_AHMLMFAFXY

open IN, "<:encoding(utf8)",$ARGV[0] or die "Can't open sequencer.info under $dir \n";

my (@ID_ddcapv3, @ID_ontissue, @ID_thyroid, @risk58);
my (@gene10_ddcapv3,@gene10_ontissue);

while(<IN>){
	chomp;
	my @a=split/\t/; 
#	print "$a[4]\n"; 测试语句
	if ($a[4]=~/ddCAP\sV3/){push @ID_ddcapv3,$a[2];}
	elsif($a[4]=~/ddCAP\son\stissue/){push @ID_ontissue,$a[2];}
	elsif($a[4]=~/Riscare58/){push @risk58,$a[2];}
	elsif($a[4]=~/Thryroid/){push @ID_thyroid,$a[2];}
	else {}

	if ($a[3]=~/PlasAim(.+?)10(.*)(基因|gene)/i){push @gene10_ddcapv3,$a[2];}
	elsif ($a[3]=~/OncoAim(.+?)10(.*)(基因|gene)/i) {push @gene10_ontissue,$a[2];}
	else {}

}close IN;

if (@ID_ddcapv3!=0){
	(open OT,">samples_file_ddcapv3.txt") || (print "Waring: Cannot creat samples_file_ddcapv3.txt\n");
	for (my $i=0;$i<=$#ID_ddcapv3;$i++){
		print OT "$ID_ddcapv3[$i]\t";
		my ($R1,$R2,$R3,$I2,$bam)=("","","","","");
		my $find=`find $dir -name "$ID_ddcapv3[$i]\*"`;chomp($find);my @f=split/\n/,$find;
		if($find!~/\//){print OT "\n";}
		for (my $i=0;$i<=$#f;$i++){
			if($f[$i]=~/\_R1\_/){$R1=$f[$i];}
			elsif($f[$i]=~/\_R2\_/){$R2=$f[$i];}
			elsif($f[$i]=~/\_R3\_/){$R3=$f[$i];}
			elsif($f[$i]=~/\_I2\_/){$I2=$f[$i];}
			elsif($f[$i]=~/\.bam/){$bam=$f[$i];}
		}
		if($R3=~/\.gz/){print OT "$R1\t$R3\t$R2\n";}
		elsif($I2=~/\.gz/){print OT "$R1\t$R2\t$I2\n";}
	}close OT;

	(open OT,">id_ddcapv3.list") || (print "Waring: Cannot creat id_ddcapv3.list\n");
	for (my $i=0;$i<=$#ID_ddcapv3;$i++){print OT "$ID_ddcapv3[$i]\n";}
	close OT;
}
else{print "Notice: No ddcapv3 sample in this batch\n"}

if (@ID_ontissue!=0){
        (open OT,">samples_file_ontissue.txt") || (print "Waring: Cannot creat samples_file_ontissue.txt\n");
        for (my $i=0;$i<=$#ID_ontissue;$i++){
		print OT "$ID_ontissue[$i]\t";
                my ($R1,$R2,$R3,$I2,$bam)=("","","","","");
                my $find=`find $dir -name "$ID_ontissue[$i]\*"`;chomp($find);my @f=split/\n/,$find;
                if($find!~/\//){print OT "\n";}
		for (my $i=0;$i<=$#f;$i++){
                        if($f[$i]=~/\_R1\_/){$R1=$f[$i];}
                        elsif($f[$i]=~/\_R2\_/){$R2=$f[$i];}
                        elsif($f[$i]=~/\_R3\_/){$R3=$f[$i];}
                        elsif($f[$i]=~/\_I2\_/){$I2=$f[$i];}
                        elsif($f[$i]=~/\.bam/){$bam=$f[$i];}
                }
                if(-e $R2){print OT "$R1\t$R2\n";}
                elsif(-e $bam){print OT "$bam\n";}
        }close OT;

	(open OT,">id_ontissue.list") || (print "Waring: Cannot creat id_ontissue.list\n");
	for (my $i=0;$i<=$#ID_ontissue;$i++){print OT "$ID_ontissue[$i]\n";}
	close OT;
}
else{print "Notice: No ddCAPonTissue sample in this batch\n"}

if (@ID_thyroid!=0){
        (open OT,">samples_file_thyroid.txt") || (print "Waring: Cannot creat samples_file_thyroid.txt\n");
        for (my $i=0;$i<=$#ID_thyroid;$i++){
                print OT "$ID_thyroid[$i]\t";
		my ($R1,$R2,$R3,$I2,$bam,$tsv)=("","","","","");
                my $find=`find $dir -name "$ID_thyroid[$i]\*"`;chomp($find);my @f=split/\n/,$find;
               	if($find!~/\//){print OT "\n";}
		for (my $i=0;$i<=$#f;$i++){
                        if($f[$i]=~/\_R1\_/){$R1=$f[$i];}
                        elsif($f[$i]=~/\_R2\_/){$R2=$f[$i];}
                        elsif($f[$i]=~/\_R3\_/){$R3=$f[$i];}
                        elsif($f[$i]=~/\_I2\_/){$I2=$f[$i];}
                        elsif($f[$i]=~/\.bam/){$bam=$f[$i];}
                }
		$tsv=$ID_thyroid[$i]."\.tsv";
                if(-e $R2){print OT "$R1\t$R2\t$tsv\n";}
                elsif(-e $bam){print OT "$bam\t$tsv\n";}
        }close OT;

	(open OT,">id_thyroid.list") || (print "Waring: Cannot creat id_thyroid.list\n");
	for (my $i=0;$i<=$#ID_thyroid;$i++){print OT "$ID_thyroid[$i]\n";}
	close OT;
}
else{print "Notice: No Thyriod sample in this batch\n"}

if (@gene10_ddcapv3!=0){
	(open OT,">10gene_id_ddcapv3.list") || (print "Waring: Cannot creat 10gene_id_ddcapv3.list\n");
	for (my $i=0;$i<=$#gene10_ddcapv3;$i++){print OT "$gene10_ddcapv3[$i]\n"}
	close OT;
}

if (@gene10_ontissue!=0){
	(open OT,">10gene_id_ontissue.list") || (print "Waring: Cannot creat 10gene_id_ontissue.list\n");
	for (my $i=0;$i<=$#gene10_ontissue;$i++){print OT "$gene10_ontissue[$i]\n"}
	close OT;
}
