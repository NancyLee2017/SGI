#!/usr/bin/perl -w
use strict;
die "perl $0 <in: clinsig.filtered.tsv.list> <out: Thyroid.results.xls>\n" unless (@ARGV ==2);
open IN,"$ARGV[0]" or die "Error: Can't open $ARGV[0]!\n";
open OT,">$ARGV[1]" or die "Error: Can't open $ARGV[1]!\n";

my $ClinVarDB="/home/hongyanli/my_file/ClinVar/clinvar.vcf";
(open CLINVAR, "$ClinVarDB") || (print "Warning: Cannot open local ClinVar Database:$ClinVarDB\n");

my %ClinVar;
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

my @SampleIDs;
my (%posi,%hash,%hash_fus,%hash_fu_gene,%qc_dedup,%qc_tl);
my (%path,%sum_site,%qc_dup);

my @key_gene=("AKT1", "BRAF", "NRAS", "KRAS", "HRAS", "RET", "PTEN", "GNAS", "TERT", "TP53");

my ($BRAF_sum005,$BRAF_sum002,$BRAF_sum_all)=(0,0,0);

while(<IN>){
    chomp;
    my $fusion=$_; $fusion=~s/report\.clinsig\.filtered\.tsv/fusion_result.tsv/;
    my $json=$_; $json=~s/report\.clinsig\.filtered\.tsv/sqm\.dedup\.json/;
    my $json_dup=$_; $json_dup=~s/report\.clinsig\.filtered\.tsv/sqm\.json/;

    my @file=split/\//;
    my $id=$file[-1]; $id=~s/\.report\.clinsig\.filtered\.tsv//;
    push @SampleIDs,$id;
    pop @file;
    my $run_folder=join"/",@file;
    $path{$id}=$run_folder."/";

    my ($gene,$pos,$ref,$alt,$type,$hgv_sc,$hgv_sp,$hgv_sp2,$transcript,$exon,$clin_sig,$clinvar_key);
    open TSV,"$_" or die "ERROR: Can't open $_ \n";
    while(<TSV>){
	chomp;
	if(/Chromosome/){next;}
	my @a=split/\t/;
#	if ($a[6]>=$ARGF[2]){
	if ($a[8]=~/PASS/){	
	    $pos=$a[0].":".$a[1];
	    $gene=$a[14];
	    $ref=$a[2];
	    $alt=$a[3];
	    $type=$a[4];
	    $hgv_sc=$a[22];$hgv_sc=~s/ENST.+:c./c./;
	    $hgv_sp=$a[23];$hgv_sp=~s/ENSP.+:p./p./;$hgv_sp2=$a[27];
	    $exon=$a[19].$a[20];
	    $transcript=$a[36];
	    $clin_sig=$a[44];
	    
	    $clinvar_key=join"\t",$pos,$ref,$alt;#用于和clinvar库进行匹配
	    my $clivar="";
	    if(exists $ClinVar{$clinvar_key}){ $clivar=$ClinVar{$clinvar_key};}else{$clivar="not found in ClinVar";}

	    my $k=join"\t",$gene,$pos,$ref,$alt,$type,$exon,$hgv_sc,$hgv_sp,$hgv_sp2,$transcript,$clin_sig,$clivar;
	    $posi{$k}+=1;
	    $a[6]=sprintf "%.3f",$a[6];
	    $hash{$k}{$id}=$a[6]."|".$a[7];
            
	    if($clin_sig=~/pathogenic/i){
	    my $sumup_key=join " ",$gene,$pos,$exon,$hgv_sc,$hgv_sp,$a[6],$clin_sig,";";#sumup表中变异信息分隔
	    $sum_site{$id}=$sum_site{$id}.$sumup_key;
	    }
	    	    
	    if(($gene=~/BRAF/)&&($hgv_sp2=~/V\/E/)){$BRAF_sum005+=1;$BRAF_sum_all+=1;} #统计BRAF V600E 出现频次
	}
	
	elsif(($a[8]!~/TSV|Blacklisted|DP_Filter|AltCount|StrandBias|_UTR_|LowQual|\tintron_variant\t|\tsynonymous_variant\t/)&&($a[6]>=0.01)){
	    if ($a[14]~~@key_gene){ #print "$a[14]\n";
		$pos=$a[0].":".$a[1];
                $gene=$a[14];
                $ref=$a[2];
                $alt=$a[3];
                $type=$a[4];
                $hgv_sc=$a[22];$hgv_sc=~s/ENST.+:c./c./;
                $hgv_sp=$a[23];$hgv_sp=~s/ENSP.+:p./p./;$hgv_sp2=$a[27];
                $exon=$a[19].$a[20];
                $transcript=$a[36];
                $clin_sig=$a[44];
   
                $clinvar_key=join"\t",$pos,$ref,$alt;
                my $clivar="";
                if(exists $ClinVar{$clinvar_key}){ $clivar=$ClinVar{$clinvar_key};}else{$clivar="not found in ClinVar";}

                my $k=join"\t",$gene,$pos,$ref,$alt,$type,$exon,$hgv_sc,$hgv_sp,$hgv_sp2,$transcript,$clin_sig,$clivar;
                $posi{$k}+=1;
                $a[6]=sprintf "%.3f",$a[6];
                $hash{$k}{$id}=$a[6]."|".$a[7]."|".$a[8];
                if($clin_sig=~/pathogenic/i){
		    my $sumup_key=join " ",$gene,$pos,$exon,$hgv_sc,$hgv_sp,$a[6],$clin_sig,";";#sumup表中变异信息分隔
		    $sum_site{$id}=$sum_site{$id}.$sumup_key;
	        }

		if(($gene=~/BRAF/)&&($hgv_sp2=~/V\/E/)){
		    $BRAF_sum_all+=1;
		    if($a[6]>=0.02){$BRAF_sum002+=1;}
		}#统计BRAF V600E 出现频次

	    }
	}
    }
    close TSV;
    
    (open FUSION, "$fusion") or (print "Warning: Can't open $id fusion_result \n"); 
    while(<FUSION>){
	if(/chr/){
	    chomp;
	    my @f=split/\t/;
	    if ($f[12]=~/Known_Cosmic_Fusion/){
		my $fusion_gene=$f[3]."-".$f[7];
		my $fusion_region=$f[0].":".$f[1]."-".$f[4].":".$f[5];
		my $fusion_freq=sprintf "%.3f",$f[10];
		$hash_fus{$fusion_gene}{$id}=join "|", $fusion_freq, $f[8], $f[9], $fusion_region;
		$hash_fu_gene{$fusion_gene}+=1;
		
		$sum_site{$id}=$sum_site{$id}."\t".$fusion_gene.":".$fusion_freq;#sumup表中fusion信息
	    }
	}
    }close FUSION;

    (open JSON, "$json") or (print "Warning: Can't open $json \n");#去重后qc_matrix, 用于质控
    while(<JSON>){
	$_=~s/\"//g; $_=~s/\}//g; $_=~s/\{//g;
	my @b=split/,/;
	for (my $i=0;$i<=$#b;$i++){
	    if ($b[$i]=~/.+:\s\d+/){
		$b[$i]=~s/\s//g;
		my @c=split/:/,$b[$i];
		if ($c[0]!~/chr/){
		    $c[1]=sprintf "%.3f", $c[1];
		    $qc_tl{$c[0]}=1;
		    $qc_dedup{$c[0]}{$id}=$c[1];
		} 
	    }
	}
    }close JSON;

    (open JSON2, "$json_dup") or (print "Warning: Can't open $json_dup \n");#去重前qc_matrix, 用于报告和sumup表
    while(<JSON2>){
	$_=~s/\"//g; $_=~s/\}//g; $_=~s/\{//g;
	my @b=split/,/;
	for (my $i=0;$i<=$#b;$i++){
	    $b[$i]=~s/\s//g;
	    my @c=split/:/,$b[$i];
	    if ($c[0]!~/chr/){
		$c[1]=sprintf "%.3f", $c[1];
		$qc_dup{$c[0]}{$id}=$c[1];
	    }
	}
    }close JSON2;

}close IN;

print OT "Gene\tLocus\tRef\tAlt\tType\tExonID\tHGVSc\tHGVSp\tProtein_br\tTranscript\tClin_sig\tClinVar_link\t";
for(my $i=0;$i<=$#SampleIDs;$i++){print OT "$SampleIDs[$i]\t";}print OT "\n";
foreach my $k(sort keys %posi){
    print OT "$k\t";
    for(my $i=0;$i<=$#SampleIDs;$i++){
	if(exists $hash{$k}{$SampleIDs[$i]}){print OT "$hash{$k}{$SampleIDs[$i]}\t";}
	else{print OT " \t";}
    }print OT "\n";
}
print OT "\n";

print OT "Fusion_Matrix\n";
foreach my $k(sort keys %hash_fu_gene){
    my $tab="\t"x10;
    print OT "$tab\t$k\t";
    for(my $i=0;$i<=$#SampleIDs;$i++){
	if(exists $hash_fus{$k}{$SampleIDs[$i]}){print OT "$hash_fus{$k}{$SampleIDs[$i]}\t";}
	else {print OT " \t";}
    }print OT "\n";
}
print OT "\n";

print OT "QC_Matrix_dedup\n";
foreach my $k(sort keys %qc_tl){
    print OT "\t"x10;print OT "\t$k\t";
    for(my $i=0;$i<=$#SampleIDs;$i++){
	if(exists $qc_dedup{$k}{$SampleIDs[$i]}){print OT "$qc_dedup{$k}{$SampleIDs[$i]}\t";}
	else {print OT " \t";}
    } print OT "\n";
}

print OT "BRAF V600E matrix\nfrequency>=0.05\t$BRAF_sum005\nfrequency0.02-0.05\t$BRAF_sum002\nTotal\t$BRAF_sum_all\n";
close OT; 

(open OT2,">sumup_filled.xls")||(print "Warning: Can't creat sumup_filled.xls\n");
print OT2 "LibID\tRunFolder\tTotal_read\tMapped_read\tMapped_rate\tOntarget_read\tOntarget_rate\t\tUniformity\tAverage_coverage\tFraction_target_covered\tFraction_known_sites_covered\tVariant\n";
for(my $i=0;$i<=$#SampleIDs;$i++){
    print OT2 "$SampleIDs[$i]\t$path{$SampleIDs[$i]}\t$qc_dup{total_read_count}{$SampleIDs[$i]}\t$qc_dup{mapped_read_count}{$SampleIDs[$i]}\t";
    my $map_rate=$qc_dup{mapped_read_count}{$SampleIDs[$i]}/$qc_dup{total_read_count}{$SampleIDs[$i]}; $map_rate=sprintf "%.3f",$map_rate;
    print OT2 "$map_rate\t$qc_dup{ontarget_read_count}{$SampleIDs[$i]}\t";
    my $tar_rate=$qc_dup{ontarget_read_count}{$SampleIDs[$i]}/$qc_dup{mapped_read_count}{$SampleIDs[$i]}; $tar_rate=sprintf "%.3f",$tar_rate;
    print OT2 "$tar_rate\t\t$qc_dup{uniformity}{$SampleIDs[$i]}\t$qc_dup{average_coverage}{$SampleIDs[$i]}\t$qc_dup{fraction_target_covered}{$SampleIDs[$i]}\t$qc_dup{fraction_known_sites_covered}{$SampleIDs[$i]}\t$sum_site{$SampleIDs[$i]}\n";
 }close OT2;
