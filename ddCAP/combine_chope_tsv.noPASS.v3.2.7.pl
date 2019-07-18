#!/usr/bin/perl -w
use strict;
die "perl $0 <in.all.tsv.list> <out.compare.xls> <AFtoBeFiltered,e.g:0.02> <sort.libID.list>\n" unless (@ARGV ==4);
open IN,"$ARGV[0]" or die "$ARGV[0] Error!\n";
open OT,">$ARGV[1]" or die "$ARGV[1] Error!\n";
open LST,"$ARGV[3]" or die "$ARGV[2] Error!\n";
my $all_clin_sig_variants="/home/tinayuan/Database/CLS_report/all_clin_sig_variants.txt";
my $blacklist="/home/tinayuan/Database/CLS_report/VUS_blacklist_clinical_report.xls";
my $FPfile="/home/tinayuan/Database/CLS_report/FP_on_clinical_report.xls";	# The FP mutations found before;
my $ClinVar="/home/hongyanli/my_file/ClinVar/clinvar.vcf";      # The VUS or confilict on ClinVar;
my @pgkb=("CYP2C8","CYP3A5","CYP2D6","DPYD","MTHFR","SULT1A1","TPMT","ABCB1","NQO1","GSTP1","CYP2C19","CYP3A4","SLC19A1","UGT1A1");
my (%hash,%posi,%path,%ClinSig,%blacklist,%FPpos,%ClinVar,%cnv,%fusion,%json,%jsondedup);
my $filtAF=$ARGV[2];
my @SampleIDs;
my %anno=("SYMBOL"=>1,"Reference"=>1,"Alternate"=>1,"Type"=>1,"Consequence"=>1,"EXON"=>1,"Protein_position"=>1,"Amino_acids"=>1,"HGVSc"=>1,"HGVSp"=>1,"Existing_variation"=>1,"RefSeq"=>1);
my @annoTT=("SYMBOL","Reference","Alternate","Type","Consequence","EXON","Protein_position","Amino_acids","HGVSc","HGVSp","Existing_variation","RefSeq");

open BLST,"$blacklist" or die "$blacklist Error!\n";
open CLIN,"$all_clin_sig_variants" or die "$all_clin_sig_variants Error!\n";
open FPF,"$FPfile" or die "$FPfile Error!\n";
open CLINVAR,"$ClinVar" or die "$ClinVar Error!\n";	# The VUS or confilict on ClinVar;

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

while(<IN>){
	chomp;
	my @file=split/\=/,$_; 
        my($cnv,$fusion1,$fusion2,$json,$jsondedup)=($file[1],"",$file[1],$file[1],$file[1]);
	$cnv=~s/report.filtered.tsv/cnv.tsv/;
        $json=~s/report.filtered.tsv/sqm.json/;
	$jsondedup=~s/report.filtered.tsv/sqm.dedup.json/;
        my @folder=split/\//,$file[1]; pop @folder;
        my $runpath=(join "/",@folder); $path{$file[0]}=$runpath;
	$fusion1=$runpath."/fusion_result.tsv";
	$fusion2=~s/report.filtered.tsv/fusion_result.tsv/;
	open TSV,"$file[1]" or die "tsv $file[1] error!\n"; push @SampleIDs,$file[0];
	my ($m,$n)=(0,0);my @anno;
	while(<TSV>){
		chomp;
		if($_=~/^Chromosome/){
			my @t=split/\t/;
			for(my $i=0;$i<=$#t;$i++){
				if(exists $anno{$t[$i]}){$anno{$t[$i]}=$i;}
				for(my $j=0;$j<=$#annoTT;$j++){
					if($t[$i] eq $annoTT[$j]){push @anno,$i; }else{next;}
				}
			}
		}else{
			my $k="";
			my @a=split/\t/;for(my $i=0;$i<=$#a;$i++){$a[$i]=~s/^\s+//;}
#			if($a[8]=~/PASS/ && $a[6]>=$filtAF){
			if(($a[8] !~ /TSV|Blacklisted|DP_Filter|AltCount|StrandBiasSnp_Filter/) && $a[6]>=$filtAF){
				$a[6]=sprintf "%.4f",$a[6];
				my $pos=join ":",$a[0],$a[1];$pos=~s/^\s+//;
				$k.=$pos;
				for(my $j=0;$j<=$#anno;$j++){
					$k.="\t";
					my $tsp="";
                                        if($a[$anno[$j]]=~/\:/){$tsp=(split/\:/,$a[$anno[$j]])[-1];}else{$tsp=$a[$anno[$j]];}
                                        $k.=" $tsp";
				}
				my $o=join "\|",$a[6],$a[7];
				my $tc=(split/\:/,$a[$anno{HGVSc}])[-1];my $tp=(split/\:/,$a[$anno{HGVSp}])[-1];
				my $k1=join "\t",$a[14],$tc; my $k2="";
				my $mark_pgkb=0;
				for(my $n=0;$n<=$#pgkb;$n++){		# whether PGKB?
                                                if($a[$anno{SYMBOL}]=~/$pgkb[$n]/){
							$mark_pgkb=1;
							$k="zPGKB_".$k;$hash{$k}{$file[0]}=$o;$posi{$k}+=1;
						}
                                }
				if(exists $FPpos{$k1}){
					$k="zFPbefore_".$k;
print "FPones\t$k\n";
				}
				if($tp=~/p.\w+/){			# Both HGVSc & HGVSp;
					$k2=join "\t",$a[14],$tp;       
					if(exists $blacklist{$k2}){
						$k="zJohnBlacklist_".$k;$hash{$k}{$file[0]}=$o;$posi{$k}+=1;
					}elsif(exists $ClinSig{$k2}){
						$hash{$k}{$file[0]}=$o;
	                                        $posi{$k}+=1;
					}else{
#						$mark_hgvsp=0;		# HGVSp don't match Blackilist & ClinSig files;
						if($mark_pgkb eq 0){$k="zVUS_".$k;}
        	                                $hash{$k}{$file[0]}=$o;$posi{$k}+=1;
					}
				}else{					# Only has HGVSc, like intron mutaion c.100+6A>G, without HGVSp..
					print "$file[0]:$_\n";
					if(exists $blacklist{$k1}){
                                                $k="zJohnBlacklist_".$k;$hash{$k}{$file[0]}=$o;$posi{$k}+=1;
                                        }elsif(exists $ClinSig{$k1}){	# if on John's all_clin_sig_variants.txt, match HGVSc & HGVSp;
						$hash{$k}{$file[0]}=$o;
						$posi{$k}+=1;
					}else{
						if($mark_pgkb eq 0){$k="zVUS_".$k;}
						$hash{$k}{$file[0]}=$o;$posi{$k}+=1;
#						if(($mark_pgkb eq 0) && ($mark_hgvsp eq 0)){$k="zVUS_".$k;$hash{$k}{$file[0]}=$o;$posi{$k}+=1;}
#						else{print "??$file[0]:$_\n";}
					}
				}
	    		}
		}
	}close TSV;
	if(-e $cnv){
	open CNV,"$cnv" or die "$cnv error!\n";
	while(<CNV>){
		chomp;
		my @a=split/\t/;
		my $k=join "\t",$a[5],$a[0],$a[1],$a[2];
		$a[3]=sprintf "%.4f",$a[3];$a[4]=sprintf "%.4f",$a[4];
		$cnv{$k}{$file[0]}=(join "|",$a[3],$a[4]);
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
			$fusion{$k}{$file[0]}=$o;
		}else{next;}
	}close FUSION;
	open JSON,"$json" or die "$json error!\n";
        while(<JSON>){
                chomp;
                my @a=split/\,/;
                for(my $i=0;$i<=$#a;$i++){
                        $a[$i]=~s/\{//g; $a[$i]=~s/\}//g; $a[$i]=~s/\"//g;
                        my ($meric,$value)=(split/\:/,$a[$i])[0,1]; $meric=~s/^\s+//; $value=~s/^\s+//;
                        if($meric=~/total_read_count|mapped_read_count|ontarget_read_count|fraction_target_covered|average_coverage|uniformity|fraction_known_sites_covered/){
                                $json{$meric}{$file[0]}=$value;
                        }
                }
        }close JSON;
	open JSOND,"$jsondedup" or die "$jsondedup error!\n";
        while(<JSOND>){
                chomp;
                my @a=split/\,/;
                for(my $i=0;$i<=$#a;$i++){
                        $a[$i]=~s/\{//g; $a[$i]=~s/\}//g; $a[$i]=~s/\"//g;
                        my ($meric,$value)=(split/\:/,$a[$i])[0,1]; $meric=~s/^\s+//; $value=~s/^\s+//;
			if($meric=~/total_read_count|mapped_read_count|ontarget_read_count|fraction_target_covered|average_coverage|uniformity|fraction_known_sites_covered/){
                                $jsondedup{$meric}{$file[0]}=$value;
                        }
                }
        }close JSOND;
}
print OT "Locus\tReference\tAlternate\ttype\tConsequence\tGene\tExonID\tHGVSc\tHGVSp\tProtein_position\tAmino_acids\tExisting_variation\tTranscript\t";
for(my $i=0;$i<=$#SampleIDs;$i++){print OT "$SampleIDs[$i]\t";}print OT "\n";
foreach my $k(sort keys %posi){
	print OT "$k\t";
	for(my $i=0;$i<=$#SampleIDs;$i++){
		if(exists $hash{$k}{$SampleIDs[$i]}){print OT "$hash{$k}{$SampleIDs[$i]}\t";}
		else{print OT " \t";}
	}
	my @t=split/\t/,$k;$t[0]=~s/^\s+//;$t[1]=~s/^\s+//;$t[2]=~s/^\s+//;
	my $pst=(split/\_/,$t[0])[-1];
	my $clinvar=join "\t",$pst,$t[1],$t[2];
	if(exists $ClinVar{$clinvar}){print OT "$ClinVar{$clinvar}\t";}
	else{print OT "\t";}
	print OT "\n";
}
print OT "\nCNV matrix\n";
foreach my $k(sort keys %cnv){
        print OT "$k","\t"x10;
        for(my $i=0;$i<=$#SampleIDs;$i++){
                if(exists $cnv{$k}{$SampleIDs[$i]}){print OT "$cnv{$k}{$SampleIDs[$i]}\t";}
                else{print OT " \t";}
        }print OT "\n";
}
print OT "\nFUSION matrix\n";
foreach my $k(sort keys %fusion){
        print OT "$k","\t"x6;
        for(my $i=0;$i<=$#SampleIDs;$i++){
                if(exists $fusion{$k}{$SampleIDs[$i]}){print OT "$fusion{$k}{$SampleIDs[$i]}\t";}
                else{print OT " \t";}
        }print OT "\n";
}
print OT "\nQC matrix for dup.bam\n";
foreach my $k(sort keys %json){
        print OT "$k","\t"x13;
        for(my $i=0;$i<=$#SampleIDs;$i++){
                if(exists $json{$k}{$SampleIDs[$i]}){print OT "$json{$k}{$SampleIDs[$i]}\t";}
                else{print OT " \t";}
        }print OT "\n";
}
print OT "\nQC matrix for dedup.bam\n";
foreach my $k(sort keys %jsondedup){
        print OT "$k","\t"x13;
        for(my $i=0;$i<=$#SampleIDs;$i++){
                if(exists $jsondedup{$k}{$SampleIDs[$i]}){print OT "$jsondedup{$k}{$SampleIDs[$i]}\t";}
                else{print OT " \t";}
        }print OT "\n";
}
close OT;

# print for sumup table;
open TB, ">$ARGV[0].forSumupTable.xls" or die "$ARGV[0].forSumupTable.xls.err\n";
print TB "LibraryID\tRunFolder\tTotal Read Count\tMapped Read Count\tMapped Rate\tOntarget Read Count\tOntarget Rate\t\tUniformity\tAverage Coverage\tFraction target covered\tFraction known sites covered\n";
while(<LST>){
        chomp;
	my $libID=$_;
	print TB "$libID\t";
        #---print QC-----#
	print TB "$path{$libID}\t";	# run folder;
        my ($ttrc,$mrc,$maprate,$orc,$ontar,$umi,$aac,$fksuc,$fksc)=($json{"total_read_count"}{$_},$json{"mapped_read_count"}{$_},0,$json{"ontarget_read_count"}{$_},0,$json{"uniformity"}{$_},$json{"average_coverage"}{$_},$json{"fraction_target_covered"}{$_},$json{"fraction_known_sites_covered"}{$_});
        $umi=sprintf "%.4f",$umi;
        $aac=sprintf "%.2f",$aac;
        $fksuc=sprintf "%.4f",$fksuc;
        $fksc=sprintf "%.4f",$fksc;
        print TB "$ttrc\t$mrc\t";
        if($ttrc>0){$maprate=sprintf "%.4f",$mrc/$ttrc;}else{$maprate="NA";}print TB "$maprate\t$orc\t";
        if($mrc>0){$ontar=sprintf "%.4f",$orc/$mrc;}else{$ontar="NA";} print TB "$ontar\t\t";
        print TB "$umi\t$aac\t$fksuc\t$fksc\t";
	#---print Mutations-------#
	foreach my $k(sort keys %posi){
		my @tp=split/\t/,$k;
		my $pt="";my @result=split/\|/,$hash{$k}{$libID};
		if($k=~/PGKB/i || $k=~/Blacklist/i){next;}
		elsif($k=~/VUS/i){$pt=join " ","VUS",$tp[5],$tp[6],$tp[7],$tp[8],$tp[4];}
		else{$pt=join " ",$tp[5],$tp[6],$tp[7],$tp[8];}
                if(exists $hash{$k}{$libID}){print TB "$pt $result[0];";}
                else{next;}
	}print TB "\t\t";
	#---print CNVs----#
	foreach my $k(sort keys %cnv){
		my @tp=split/\t/,$k;
		my @result=split/\|/,$cnv{$k}{$libID};
#        	if($result[0]>=3 && $result[1]>=10){print TB "$tp[0] $result[0];";}
		if($result[0]>=4){print TB "$tp[0]=$result[0];";}
                else{next;}
	}print TB "\t";
	#---print Fusions----#
	foreach my $k(sort keys %fusion){
                my @tp=split/\t/,$k;
                my @result=split/\|/,$fusion{$k}{$libID};
                if(exists $fusion{$k}{$libID}){print TB "$tp[7]-$tp[3] $result[2];";}
                else{next;}
        }print TB "\n";
}close LST;

print TB "\n";

open LST,"$ARGV[3]" or die "$ARGV[2] Error!\n";
while(<LST>){
        chomp;
        my $libID=$_;
=pod
        print TB "$libID has";
	#---print Mutations-------#
        foreach my $k(sort keys %posi){
                my @tp=split/\t/,$k;
                my $pt="";my @result=split/\|/,$hash{$k}{$libID};
                if($k=~/PGKB/i || $k=~/Blacklist/i || $k=~/FPbefore/i){next;}
                elsif($k=~/VUS/i){if($tp[8]=~/\w+/){$pt=join "",$tp[5],$tp[8],"(VUS)";}else{$pt=join "",$tp[5],$tp[7],"(VUS)";}}
                else{if($tp[8]=~/\w+/){$pt=join "",$tp[5],$tp[8];}else{$pt=join "",$tp[5],$tp[7];}}
                if(exists $hash{$k}{$libID}){print TB "$pt,";}
                else{next;}
        }print TB ";";
=cut
        #---print CNVs----#
        foreach my $k(sort keys %cnv){
                my @tp=split/\t/,$k;
                my @result=split/\|/,$cnv{$k}{$libID};
                if($result[0]>=4){print TB "Sample $libID has CNV: $tp[0] = $result[0],\n";}
                else{next;}
        };
        #---print Fusions----#
        foreach my $k(sort keys %fusion){
                my @tp=split/\t/,$k;
                my @result=split/\|/,$fusion{$k}{$libID};
                if(exists $fusion{$k}{$libID}){print TB "Sample $libID has fusion: $tp[7]-$tp[3] = $result[2]\n";}
                else{next;}
        }
}close LST;
close TB;

