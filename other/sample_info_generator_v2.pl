#!/usr/bin/perl -w

use utf8;

die "perl $0 <sumup.lines> <id.list>\n" unless (@ARGV ==2);

my %hash;
#open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open IN,"<:encoding(utf8)",$ARGV[0] or die "Error! Cannot open $ARGV[0]\n";

my $time=join(",",localtime());
my @temp=split/,/,$time;
my $year=$temp[5]+1900;
my $month=$temp[4]+1;
my $day=$temp[3];
my $today=join("/",$year,$month,$day);
print "Today is $today\n";

while(<IN>){
	chomp;
	my @t=split/\t/;
	if((!$t[0])||($t[0]=~/^\s$/)){shift @t;}
	my $libID=$t[36];
	my $tsv_name="$libID".".tsv";
	$hash{$libID}=1;

	open OT,">$tsv_name" or die "Error! Cannot creat $tsv_name\n";
	print "$t[8] analysis is $t[11]\n";
	
	if ($t[9]=~/A01D|D53D|H01D|G03D|D50D/){#ddCAPonTissue，OncoAimDNA, CRC4货号；ddCAPV3货号; 甲状腺癌TC20货号； CRC22,HBOC19货号
		print OT "#\n";
		print OT "Name\t$t[7]\n";
		if($t[13]=~/^\s/){$t[13]="未提供";}
		print OT "Gender\t$t[13]\n";
		if($t[12]=~/^\s/){$t[12]="未提供";}
		print OT "Age\t$t[12]\n";
		if($t[4]=~/^\s/){$t[4]="未提供";}
		print OT "Institution\t$t[4]\n";
		if($t[6]=~/\//){$t[6]="未提供";}
		print OT "Physician\t$t[6]\n";
		if($t[14]=~/^\s/){$t[14]="未提供";}
		print OT "Diagnosis\t$t[14]\n";
		print OT "Tumor_Staging_and_Grading\t\n";#sumup表未提供该列
		print OT "Sample_Type\t$t[18]\n";
		if($t[15]=~/^\s/){$t[15]="未提供";}
		print OT "Sampling_Location\t$t[15]\n";#取样部位
		if($t[16]=~/^\s/){$t[16]="未提供";}
		print OT "Sampling_Date\t$t[16]\n";#取样日期
		print OT "Sample_Shipping_Date\t$t[0]\n";#送检日期
		print OT "Specimen_Received_Date\t$t[1]\n";#收样日期
		if ($t[14]=~/家族病史/){print OT "Fam_History\t$t[14]\n";}#家族史/肿瘤家族史
		else{print OT "Fam_History\t未提供\n";}
		print OT "Nuc_Iso_Date\t$t[30]\n";#核酸提取日期
		print OT "Nuc_Iso_Type\t$t[18]\n";#核酸提取组织类型
		$t[24]=~s/whole blood//;
		print OT "Nuc_Iso_Amount\t$t[24]\n";#核酸提取样品用量
		print OT "Nuc_Vol\t100\n";#核酸体积，默认提100ul
		my $nuc_con="未提供";
		if((!$t[26])||($t[26]=~/^\s$/)){$nuc_con="未提供";} 
		else {$nuc_con=($t[26]/100);}
		print OT "Nuc_Con\t$nuc_con\n";#核酸浓度
		print OT "Nuc_Int_Evaluation\t好\n";#血液默认为“好”
		print OT "Lib_Date\t$t[39]\n";#文库构建日期
		print OT "Lib_Nuc_Amount\t$t[33]\n";#文库构建核酸用量
		print OT "Lib_Con\t$t[37]\n";#文库浓度
		print OT "Lib_Vol\t40\n";#文库体积，sumup表未提供该列，默认为40 (20--50均有)
		print OT "Insert_Size\t380\n";#sumup表未提供该列，默认值380
		print OT "Analysis_Date\t$today\n";
		print OT "MolPathNo\t\n";#分子病理检测号，sumup表未提供该列
		print OT "Medicine\t$t[14]\n";#用药史
		if ($t[14]=~/既往病史/){print OT "Anamnesis\t$t[14]\n";}#既往病史
		else{print OT "Anamnesis\t未提供\n";}
		print OT "Treatment_History\t$t[14]\n";#治疗史
		if ($t[14]=~/病理诊断/){print OT "Pathological_Diagnosis\t$t[14]\n";}#病理诊断
		else{print OT "Pathological_Diagnosis\t\n";}
		
		print "$t[8] 's tsv is done!\n";
	}
	else {print "\nERROR:$t[8] 新货号无法识别,请确认项目!!!\n"}
	close OT;
}
close IN;

open IN2,"$ARGV[1]" or die "Error! Cannot open $ARGV[1]\n";
while (<IN2>){
	chomp;
	my $tsv_name=$_.".tsv";
	if (exists $hash{$_}){next;}
	else {`touch $tsv_name`} 
}
