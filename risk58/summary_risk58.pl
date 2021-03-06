#!/usr/bin/perl -w
#非良性位点加入clinvar注释
use strict;
die "perl $0 <path.list> <out.xls>\n" unless (@ARGV ==2);

my $ClinVar_vcf="/home/pluto/hongyanli/DataBase/clinvar.vcf";
my %ClinVar;
open CLINVAR,"$ClinVar_vcf" or die "Open ClinVar file Error!\n";
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
}
close CLINVAR;

open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT,">$ARGV[1]" or die "Error! Cannot open $ARGV[1] \n";
#print OT "SampleID\tWorkPath\tGene\tPosition\tExon\tFrequency\tHGVsc\tHGVsp\tClin_Sig\n";

my (%hash_qc,%hash_report,%hash_benign,%hash_cnv,%var_report,%var_benign,%var_cnv);
my @sample_IDs;
my $workspace_dir='/media/pluto/Riskcare53/Data';
my @qc=("Total_reads","Mapping_rate","Coverage_mean","Uniformity","Target_cover_rate_200X");#QC行名

while(<IN>){
	chomp;
	my $workspace_path;
	if(/report_.*-M/){$workspace_path=$_;}
	else{print "Warning: $_ doesn't fit RISCARE format!\n"; next;}
	my @a=split/\//;
	
	my $libID=(split/_/,$a[-1])[-1];

#	my (@pathgenic, @likely_pathgenic, @uncertain, @inconlusive, @benign, @cnvs);#分类存放结果
#	my $workspace_name="report_"."$libID";
#	my $workspace_find=`find $workspace_dir -type d -name "$workspace_name"`;
#	my $workspace_path=(split/\n|\t/,$workspace_find)[-1];#如果有多次分析结果，只保留最新的一次
#	chomp $workspace_path;#分析结果路径
	
	my $sample_ID="$libID"."="."$workspace_path";
	push @sample_IDs, $sample_ID;
	
	my $qc_name="$libID"."*_QCtable.txt";
	my $qc_report=`find "$workspace_path" -name "$qc_name"`;
	chomp $qc_report;
	
	my ($tsv_name, $tsv);
	if ($libID=~/-FF\d/){ #组织样本
		$tsv_name="$libID"."*_somatic.tsv"; 
		$tsv=`find "$workspace_path" -name "$tsv_name"`;
	}
	else{ #血液样本
		$tsv_name="$libID"."*_germline.tsv";
		$tsv=`find "$workspace_path" -name "$tsv_name"`;
	}
	chomp $tsv;
		
	my $cnv_gene_name="$libID"."*gene_CNV.tsv";
	my $cnv_gene_tsv=`find "$workspace_path" -name "$cnv_gene_name"`;
	chomp $cnv_gene_tsv;

	my $cnv_exon_name="$libID"."*exon_CNV.tsv";
	my $cnv_exon_tsv=`find "$workspace_path" -name "$cnv_exon_name"`;
	chomp $cnv_exon_tsv;

	print "$libID Start...\n";
	
#处理QC信息
	(open QC,"$qc_report")|| (print "ERROR: Can't open $libID QC file $qc_report !!\n");
	while (<QC>){
		chomp;
		if($_=~/Total reads number/){my @temp=split/\t/;$temp[1]=$temp[1]."M";$hash_qc{$sample_ID}{$qc[0]}=$temp[1];}
		elsif($_=~/Reads mapping rate/){my @temp=split/\t/;$hash_qc{$sample_ID}{$qc[1]}=$temp[1];}
		elsif($_=~/Probe coverage mean/){my @temp=split/\t/;$temp[1]=sprintf "%d",$temp[1];$hash_qc{$sample_ID}{$qc[2]}=$temp[1];}
		elsif($_=~/Probe Uniformity/){my @temp=split/\t/;$hash_qc{$sample_ID}{$qc[3]}=$temp[1];}
		elsif($_=~/Fraction of official target covered with at least 200X/){my @temp=split/\t/;$hash_qc{$sample_ID}{$qc[4]}=$temp[1];}
	}close QC;
	
#处理SNV
	(open TSV,"$tsv") || (print "ERROR: Can't open $libID SNV file $tsv!!\n");
	while(<TSV>){
		chomp;
		next if(/Chromosome/);
		if ($_=~/(B|b)enign/){
			my @a=split/\t/;
			my $pos="$a[0]".":"."$a[1]";
			my $ref=$a[2];
			my $alt=$a[3];
			my $type=$a[4];
#			my $genotype=$a[5];#不再把genotype作为key值
			$a[18]=~s/\/.+//;
			my $exon="$a[17]"."$a[18]";
			my $maf=sprintf "%.3f",$a[6];
			my $depth=$a[7];
			$a[20]=~s/ENST.+:c/c/;
			my $cdna=$a[20];
			my $aa=$a[21];
			if ($aa=~/ENST.+\(p\.=\)/){next;}#更改输出格式，不统计同义benign位点
			else{$aa=~s/ENSP.+:p/p/;}
			$a[42]=~s/\d-//;
			my $sig=$a[42];
			my $key=join "\t",$a[12],$pos,$exon,$ref,$alt,$cdna,$aa,$type,$sig;
			$hash_benign{$sample_ID}{$key}="$maf"."|"."$depth";
			$var_benign{$key}+=1;
		}
		else{
			my @a=split/\t/;
			my $pos="$a[0]".":"."$a[1]";
			my $ref=$a[2];
			my $alt=$a[3];
			my $type=$a[4];
#			my $genotype=$a[5];
			$a[18]=~s/\/.+//;
			my $exon="$a[17]"."$a[18]";
			my $maf=sprintf "%.3f",$a[6];
			my $depth=$a[7];
			$a[20]=~s/ENST.+:c/c/;
			my $cdna=$a[20];
			my $aa=$a[21];
			if ($aa=~/ENST.+\(p\.=\)/){$aa='p.=';}
			else{$aa=~s/ENSP.+:p/p/;}
			$a[42]=~s/\d-//;
			my $sig=$a[42];
			my $key=join "\t",$a[12],$pos,$exon,$ref,$alt,$cdna,$aa,$type,$sig;
			$hash_report{$sample_ID}{$key}="$maf"."|"."$depth";
			$var_report{$key}+=1;
		}
	}close TSV;
		
#处理CNV
	(open CNV1,"$cnv_gene_tsv") || (print "ERROR: Can't open $libID gene CNV file!!\n");
	while(<CNV1>){
		chomp;
		if(/Gene_Symbol/){next;}
		else {
			my @b=split/\t/;
			my $gene=$b[0];
			my $pos=$b[1];
			my $ploidy=$b[2];
			my $Zscore=$b[3];
			my $key=join "\t",$gene,$pos,"-";
#			$key="gene_CNV:"."$show";
			if ($ploidy<1.2){#cutoff值
#				push @cnvs,$show;
				$hash_cnv{$sample_ID}{$key}="$ploidy"."|"."$Zscore";
				$var_cnv{$key}+=1;
#				print OT "$sample_ID\t$show\n";
			}
		}
	}close CNV1;
	
	(open CNV2,"$cnv_exon_tsv") || (print "ERROR: Can't open $libID exon CNV file!!\n");
	while(<CNV2>){
		chomp;
		if(/Gene_Symbol/){next;}
		else {
			my @b=split/\t/;
			my $gene=$b[0];
			my $exon="exon"."$b[1]";
			my $pos=$b[2];
			my $ploidy=$b[3];
			my $Zscore=$b[4];
			my $key=join "\t",,$gene,$pos,$exon;
#			$show="exon_CNV:"."$show";
			if ($ploidy<1.2){
#				push @cnvs,$show;
				$hash_cnv{$sample_ID}{$key}="$ploidy"."|"."$Zscore";
				$var_cnv{$key}+=1;
#				print OT "$sample_ID\t$show\n";
			}
		}
	}close CNV2;
#	for (my $i=0;$i<=$#cnvs;$i++){$hash_cnv{$sample_ID}{$cnvs[$i]}=1;$hash_cnv{$cnvs[$i]}+=1;} #记录gene_CNV
#	print "$libID read all files done!\n";
}close IN;

#打印非良性的SNV matrix
print OT "Reported SNV results:\n";
print OT "Gene\tPosition\tExon\tRef\tAlt\tHGVsc\tHGVsp\tType\tClin_Sig\t";
for (my $i=0;$i<=$#sample_IDs;$i++){print OT "$sample_IDs[$i]\t";}
print OT "\n";
foreach my $k (sort keys %var_report){
	print OT "$k\t";
	for (my $i=0;$i<=$#sample_IDs;$i++){
		if (exists $hash_report{$sample_IDs[$i]}{$k}){
			print OT "$hash_report{$sample_IDs[$i]}{$k}\t";
		}
		else{print OT "\t";}
	}
	my @t=split/\t/,$k;
	my $clin_key=join"\t",$t[1],$t[3],$t[4];
	my $clin_sig;
	if (exists $ClinVar{$clin_key}){$clin_sig=$ClinVar{$clin_key};}
    else {$clin_sig='Not included in ClinVar';}
	print OT "$clin_sig\n";
}
print OT "\n\n";

#打印CNV matrix
print OT "CNV results:\n";
foreach my $k (sort keys %var_cnv){
	print OT "$k\t"; print OT "\t"x6;
	for (my $i=0;$i<=$#sample_IDs;$i++){
		if (exists $hash_cnv{$sample_IDs[$i]}{$k}){
			print OT "$hash_cnv{$sample_IDs[$i]}{$k}\t";
		}
		else{print OT "\t";}
	}print OT "\n";
}
print OT "\n\n";

#打印良性位点matrix
print OT "Benign Site:\n";
foreach my $k (sort keys %var_benign){
	print OT "$k\t";
	for (my $i=0;$i<=$#sample_IDs;$i++){
		if (exists $hash_benign{$sample_IDs[$i]}{$k}){
			print OT "$hash_benign{$sample_IDs[$i]}{$k}\t";
		}
		else{print OT "\t";}
	}
	my @t=split/\t/,$k;
	my $clin_key=join"\t",$t[1],$t[3],$t[4];
	my $clin_sig;
	if (exists $ClinVar{$clin_key}){$clin_sig=$ClinVar{$clin_key};}
    else {$clin_sig='Not included in ClinVar';}
	print OT "$clin_sig\n";
}
print OT "\n\n";
#打印QC matrix
print OT "Sample's QC:\n";
#print OT "SampleID\tTotal_reads\tMapping_rate\tCoverage_mean\tUniformity\tTarget_cover_rate_200X\n";
foreach my $tl (@qc){
	print OT "\t"x8;
	print OT "$tl\t";
	for (my $i=0;$i<=$#sample_IDs;$i++){
		if (exists $hash_qc{$sample_IDs[$i]}{$tl}){print OT "$hash_qc{$sample_IDs[$i]}{$tl}\t";}
		else{print OT "\t";}
	}print OT "\n";
}
close OT;

