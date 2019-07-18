#!/usr/bin/perl -w
use strict;
die "perl $0 <in.all.tsv.list> <out.xls>\n" unless (@ARGV ==2);
open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";
#open LST,"$ARGV[3]" or die "$ARGV[2] Error!\n";
my $all_clin_sig_variants="/home/tinayuan/Database/CLS_report/all_clin_sig_variants.txt";
my $blacklist="/home/tinayuan/Database/CLS_report/VUS_blacklist_clinical_report.xls";
my $FPfile="/home/tinayuan/Database/CLS_report/FP_on_clinical_report.xls";	# The FP mutations found before;
my $ClinVar="/data/home/tinayuan/Database/ClinVar/clinvar.vcf";      # The VUS or confilict on ClinVar;
#my $key_site="/home/hongyanli/workspace/summary/ddCAPonTissue_2018/key_site.list"; 
my @pgkb=("CYP2C8","CYP3A5","CYP2D6","DPYD","MTHFR","SULT1A1","TPMT","ABCB1","NQO1","GSTP1","CYP2C19","CYP3A4","SLC19A1","UGT1A1");
my (%hash,%posi,%path,%ClinSig,%blacklist,%FPpos,%ClinVar,%cnv,%fusion,%json,%jsondedup);
#my $filtAF=$ARGV[2];
#my %anno=("SYMBOL"=>1,"Reference"=>1,"Alternate"=>1,"Type"=>1,"Consequence"=>1,"EXON"=>1,"Protein_position"=>1,"Amino_acids"=>1,"HGVSc"=>1,"HGVSp"=>1,"Existing_variation"=>1,"RefSeq"=>1);
#my @annoTT=("SYMBOL","Reference","Alternate","Type","Consequence","EXON","Protein_position","Amino_acids","HGVSc","HGVSp","Existing_variation","RefSeq");

#open BLST,"$blacklist" or die "$blacklist Error!\n";
#open CLIN,"$all_clin_sig_variants" or die "$all_clin_sig_variants Error!\n";
#open FPF,"$FPfile" or die "$FPfile Error!\n";
open CLINVAR,"$ClinVar" or die "$ClinVar Error!\n";	# The VUS or confilict on ClinVar;
=pod
while(<BLST>){
	chomp;
	next if($_=~/^\#/);
	my @a=split/\t/;
#	my $k=join "\t",$a[0],$a[1],$a[2];
	my $k="";
	if($a[1]=~/\+|-/ || $a[2]=~/\?|NA/ || ($a[2] eq "N/A") || ($a[2] eq "-")){
		$k=join "\t",$a[0],$a[1];	# $k=gene HGVSc;
		$blacklist{$k}=$a[-4];	
	}
	else{
		$k=join "\t",$a[0],$a[2];	# $k=gene HGVSp;
		$blacklist{$k}=$a[-4];
	}
}close BLST;

while(<FPF>){
	chomp;
	my @a=split/\t/;for(my $i=0;$i<=$#a;$i++){$a[$i]=~s/^\s+//;}
	my $k=join "\t",$a[3],$a[4];
	$FPpos{$k}=$_;
}close FPF;
=cut
while(<CLINVAR>){
	chomp;
	next if($_=~/^\#/);
	my @a=split/\t/;
	my @b=split/\;/,$a[-1];
	my $clins="";
	for(my $i=0;$i<=$#b;$i++){if($b[$i]=~/(CLNSIG=)(\w+)/){$clins=$2;}}
	$a[0]="chr".$a[0];
	$a[2]="https://www.ncbi.nlm.nih.gov/clinvar/variation/".$a[2]."/";
	my $k=join ":",$a[0],$a[1];$k=join "\t",$k,$a[3],$a[4];
	my $o=join ",","ClinVar",$clins,$a[2];
	$ClinVar{$k}=$o;
}close CLINVAR;
=pod
while(<CLIN>){
	chomp;
	my @a=split/\t/;my $hgvsc="";if($a[2]=~/\:/){$hgvsc=(split/\:/,$a[2])[-1];}else{$hgvsc=$a[2];}
#	my $k=join "\t",$a[1],$hgvsc,$a[3];
	my $k="";
	if($hgvsc=~/\+/ || $a[3]=~/\?|NA/ || ($a[3] eq "N/A") || ($a[3] eq "-")){
		$k=join "\t",$a[1],$hgvsc;	# $k=gene HGVSc;
		$ClinSig{$k}=$_;	
	}
	elsif($hgvsc=~/\-/){
		if($a[3]=~/p.\w+/){$k=join "\t",$a[1],$a[3];}
		else{
			$k=join "\t",$a[1],$hgvsc;      # $k=gene HGVSc, like c.112-1_113dup or c.97-2A>T;
		}
                $ClinSig{$k}=$_;
	}
	else{
		$k=join "\t",$a[1],$a[3];	# $k=gene HGVSp;
		$ClinSig{$k}=$_;
	}
}close CLIN;
=cut

my $total_num=0;#统计样本总数
my @SampleIDs;
my %var_count;
my($L858R,$T790M,$L792,$C797,$del_19,$ins_20,$G12D,$G13D,$V600E);#分别统计各重要位点检出次数
while(<IN>){
	$total_num+=1;
	chomp;
	my $samplePATH=$_;
	my @file=split/\=/,$_; 
	push @SampleIDs,$samplePATH;
	my($cnv,$fusion1,$fusion2,$json,$jsondedup,$process)=($file[1],"",$file[1],$file[1],$file[1],$file[1]);
	$cnv=~s/report.filtered.tsv/cnv.tsv/;
	$json=~s/report.filtered.tsv/sqm.json/;
	$jsondedup=~s/report.filtered.tsv/sqm.dedup.json/;
	$process=~s/report.filtered.tsv/processed.tsv/;#新增process.tsv路径
#	print "$process\n";
	my @folder=split/\//,$file[1]; pop @folder;
	my $runpath=(join "/",@folder); $path{$samplePATH}=$runpath;
	$fusion1=$runpath."/fusion_result.tsv";
	$fusion2=~s/report.filtered.tsv/fusion_result.tsv/;
	
#	my (%pocess_pos);
	my ($gene,$pos,$ref,$alt,$type,$hgv_sc,$hgv_sp,$hgv_sp2,$location,$exon,$section);
	my ($key,$o);
	$var_count{$samplePATH}=0;#单个样本检出突变总数
	(open PTSV,"$process") || (print "File: $process not exist!!!\n");
	while(<PTSV>){
		chomp;
		if ($_=~/^Gene/){next;}
		else {
			my @a=split/\t/;
			$a[2]="chr".$a[2];
			my $k=join "\t", $a[2],$a[3],$a[4],$a[5];
#			$pocess_pos{$samplePATH}{$k}=1;
			$gene=$a[0];$pos=$a[2].":".$a[3];$ref=$a[4];$alt=$a[5];$type=$a[6];$hgv_sc=$a[13];$hgv_sp=$a[14];$hgv_sp2=$a[15],$location=$a[16],$section=$a[19];
			if($location=~/Exon/){$exon=$a[17];}
			else{$exon=$a[18];}
			$key=join"\t",$gene,$pos,$ref,$alt,$type,$location,$exon,$hgv_sc,$hgv_sp,$hgv_sp2,$section; 
			$posi{$key}=1;
			if ($section=~/Main|VUS|Low/){$var_count{$samplePATH}+=1;}#定义阳性样本范围
			if ($gene=~/EGFR/){
				if ($hgv_sp2=~/L858R/){$L858R+=1;}
				elsif($hgv_sp2=~/T790M/){$T790M+=1;}
				elsif($hgv_sp2=~/L792/){$L792+=1;}
				elsif($hgv_sp2=~/C797/){$C797+=1;}
				elsif($type=~/indel|delins/ && $exon==19){$del_19+=1;}
				elsif($type=~/indel/ && $exon==20){$ins_20+=1;}
			}
			elsif($gene=~/BRAF/ && $hgv_sp2=~/V600E/){$V600E+=1;}
			elsif($gene=~/KRAS/ && $hgv_sp2=~/G12D/){$G12D+=1;}
			elsif($gene=~/KRAS/ && $hgv_sp2=~/G13D/){$G13D+=1;}
			
			
			open TSV,"$file[1]" or die "ERROR! Can't open $file[1]!\n"; 
			while(<TSV>){
				chomp;
				if($_=~/^Chromosome/){next;}
				else{
					my @a=split/\t/;
					my $m=join"\t",$a[0],$a[1],$a[2],$a[3];
					if($m eq $k){
						$a[6]=sprintf "%.4f",$a[6];
						$o=join "|", $a[6],$a[7];
						$hash{$key}{$samplePATH}=$o;
					}
				}
			}close TSV;
		}
	}close PTSV;

	if(-e $cnv){
	open CNV,"$cnv" or die "$cnv error!\n";
	while(<CNV>){
		chomp;
		my @a=split/\t/;
		my $k=join "\t",$a[5],$a[0],$a[1],$a[2];
		$a[3]=sprintf "%.4f",$a[3];$a[4]=sprintf "%.4f",$a[4];
		$cnv{$k}{$samplePATH}=(join "|",$a[3],$a[4]);
		}close CNV;
	}
	if(-e $fusion1){open FUSION,"$fusion1" or die "$fusion1 error!\n";}
	elsif(-e $fusion2){open FUSION,"$fusion2" or die "$fusion2 error!\n";}
	else{print "Fusion file name are wrong! Please check the fusion file name\n";}
	while(<FUSION>){
		chomp;
		if($_=~/Known_Cosmic_Fusion/){
			my @a=split/\t/;$a[10]=sprintf "%.4f",$a[10];
			my $k=join "\t",$a[0],$a[1],$a[2],$a[3],$a[4],$a[5],$a[6],$a[7];my $o=join "|",$a[8],$a[9],$a[10],$a[11];
			$fusion{$k}{$samplePATH}=$o;
		}else{next;}
	}close FUSION;
	
	(open JSON,"$json") ||( print "ERROR: Can't open $json !\n");
        while(<JSON>){
                chomp;
                my @a=split/\,/;
                for(my $i=0;$i<=$#a;$i++){
                        $a[$i]=~s/\{//g; $a[$i]=~s/\}//g; $a[$i]=~s/\"//g;
						my @tem=split/\:/,$a[$i];
						my $meric=$tem[0];
						my $value=$tem[1];
#						$meric=~s/^\s+//; $value=~s/^\s+//;
                        if($meric=~/total_read_count|mapped_read_count|ontarget_read_count|fraction_target_covered|average_coverage|uniformity|fraction_known_sites_covered/){
                                $json{$meric}{$samplePATH}=$value;
                        }
                }
        }close JSON;
	(open JSOND,"$jsondedup") || (print "ERROR: Can't open $jsondedup !\n");
        while(<JSOND>){
                chomp;
                my @a=split/\,/;
                for(my $i=0;$i<=$#a;$i++){
                        $a[$i]=~s/\{//g; $a[$i]=~s/\}//g; $a[$i]=~s/\"//g;
						my @tem=split/\:/,$a[$i];
						my $meric=$tem[0];
						my $value=$tem[1];
#						$meric=~s/^\s+//; $value=~s/^\s+//;
			if($meric=~/total_read_count|mapped_read_count|ontarget_read_count|fraction_target_covered|average_coverage|uniformity|fraction_known_sites_covered/){
                                $jsondedup{$meric}{$samplePATH}=$value;
                        }
                }
        }close JSOND;
}

print OT "Gene\tLocus\tRef\tAlternate\tType\tExon\tExonID\tHGVSc\tHGVSp\tProtein_br\tSection\t";
for(my $i=0;$i<=$#SampleIDs;$i++){print OT "$SampleIDs[$i]\t";}print OT "\n";
foreach my $k(sort keys %posi){
	print OT "$k\t";
	for(my $i=0;$i<=$#SampleIDs;$i++){
		if(exists $hash{$k}{$SampleIDs[$i]}){print OT "$hash{$k}{$SampleIDs[$i]}\t";}
		else{print OT " \t";}
	}
	my @t=split/\t/,$k;
#	my $pst=(split/\_/,$t[0])[-1];
	my $clinvar=join "\t",$t[1],$t[2],$t[3];
	if(exists $ClinVar{$clinvar}){print OT "$ClinVar{$clinvar}\t";}
	else{print OT "\t";}
	print OT "\n";
}
print OT "\nCNV matrix\n";
foreach my $k(sort keys %cnv){
        print OT "$k","\t"x8;
        for(my $i=0;$i<=$#SampleIDs;$i++){
                if(exists $cnv{$k}{$SampleIDs[$i]}){print OT "$cnv{$k}{$SampleIDs[$i]}\t";}
                else{print OT " \t";}
        }print OT "\n";
}
print OT "\nFUSION matrix\n";
foreach my $k(sort keys %fusion){
        print OT "$k","\t"x4;
        for(my $i=0;$i<=$#SampleIDs;$i++){
                if(exists $fusion{$k}{$SampleIDs[$i]}){print OT "$fusion{$k}{$SampleIDs[$i]}\t";}
                else{print OT " \t";}
        }print OT "\n";
}
print OT "\nQC matrix for dup.bam\n";
foreach my $k(sort keys %json){
        print OT "$k","\t"x11;
        for(my $i=0;$i<=$#SampleIDs;$i++){
                if(exists $json{$k}{$SampleIDs[$i]}){print OT "$json{$k}{$SampleIDs[$i]}\t";}
                else{print OT " \t";}
        }print OT "\n";
}
print OT "\nQC matrix for dedup.bam\n";
foreach my $k(sort keys %jsondedup){
        print OT "$k","\t"x11;
        for(my $i=0;$i<=$#SampleIDs;$i++){
                if(exists $jsondedup{$k}{$SampleIDs[$i]}){print OT "$jsondedup{$k}{$SampleIDs[$i]}\t";}
                else{print OT " \t";}
        }print OT "\n";
}
print OT "\nKeySite_sum:\n";
print OT "L858R\t$L858R\nT790M\t$T790M\nL792\t$L792\nC797\t$C797\nExon19_indel\t$del_19\nExon20_indel\t$ins_20\nG12D\t$G12D\nG13D\t$G13D\nV600E\t$V600E\n";

my $TP=0;
for(my $i=0;$i<=$#SampleIDs;$i++){
	if ($var_count{$SampleIDs[$i]}>0){$TP+=1;}
}
print OT "\nPositiveSampleNum:\t$TP\n";
print OT "\nTotalSampleNum:\t$total_num\n";
close OT;