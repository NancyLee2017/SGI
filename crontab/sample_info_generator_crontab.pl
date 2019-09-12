#!/usr/bin/perl 
use utf8;
die "perl $0 <sumup.lines> <id.list> <pipeline>\n" unless (@ARGV ==3);

open IN,"<:encoding(utf8)",$ARGV[0] or die "Error! Cannot open sumup file:$ARGV[0]\n";

my $time=join(",",localtime());
my @temp=split/,/,$time;
my $year=$temp[5]+1900;
my $month=$temp[4]+1;
my $day=$temp[3];
my $today=join("/",$year,$month,$day);

my $pipeline=$ARGV[2];
my %hash;

while(<IN>){
	chomp;
	my @t=split/\t/;
	if((!$t[0])||($t[0]=~/^\s$/)){shift @t;}
	my $libID=$t[36];
	my $tsv_name="$libID".".tsv";
	
	if ($pipeline=~/ontissue/){
		if (($t[11]=~/ddCAP\son\stissue/i)||($t[9]=~/A01D/)) {
			open OT,">$tsv_name" or die "Error! Cannot creat output file: $tsv_name\n";
			$hash{$libID}=1;
		
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
		        print OT "Diagnosis\t$t[14]\n";#临床诊断
        		print OT "Sampling_Location\t$t[15]\n";#取样部位
		        if($t[16]=~/^\s/){$t[16]="未提供";}
		        print OT "Sampling_Date\t$t[16]\n";#取样日期
		        print OT "Sample_Shipping_Date\t$t[0]\n";#送检日期
		        print OT "Specimen_Received_Date\t$t[1]\n";#收样日期
			print OT "Analysis_Date\t$today\n";
			print OT "MolPathNo\t\n";#分子病理检测号，sumup表未提供该列
			print OT "Medicine\t$t[14]\n";#用药史
			if ($t[14]=~/既往病史/){print OT "Anamnesis\t$t[14]\n";}#既往病史
			else{print OT "Anamnesis\t未提供\n";}
			print OT "Treatment_History\t$t[14]\n";#治疗史
			if ($t[14]=~/病理诊断/){print OT "Pathological_Diagnosis\t$t[14]\n";}#病理诊断
			else{print OT "Pathological_Diagnosis\t\n";}
	
			close OT;
		}
	}
	elsif ($pipeline=~/ddcapv3/){
		if (($t[11]=~/ddCAP\sV3/i)||($t[9]=~/D53D/)) {
			open OT,">$tsv_name" or die "Error! Cannot creat output file: $tsv_name\n";
			
			$hash{$libID}=1;
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
			print OT "Diagnosis\t$t[14]\n";#临床诊断
			print OT "Sample_Type\t$t[18]\n";
			if($t[15]=~/^\s/){$t[15]="未提供";}
			print OT "Sampling_Location\t$t[15]\n";#取样部位
			if($t[16]=~/^\s/){$t[16]="未提供";}
			print OT "Sampling_Date\t$t[16]\n";#取样日期
			print OT "Sample_Shipping_Date\t$t[0]\n";#送检日期
			print OT "Specimen_Received_Date\t$t[1]\n";#收样日期
			print OT "Analysis_Date\t$today\n";
			print OT "MolPathNo\t\n";#分子病理检测号，sumup表未提供该列
			print OT "Medicine\t$t[14]\n";#用药史
			if ($t[14]=~/既往病史/){print OT "Anamnesis\t$t[14]\n";}#既往病史
			else{print OT "Anamnesis\t未提供\n";}
			print OT "Treatment_History\t$t[14]\n";#治疗史
			if ($t[14]=~/病理诊断/){print OT "Pathological_Diagnosis\t$t[14]\n";}#病理诊断
			else{print OT "Pathological_Diagnosis\t\n";}
		
			close OT;
		}
	}
	elsif ($pipeline=~/thyroid/){
		if ($t[10]=~/甲状腺/){ #甲状腺癌27基因（Thyroid V2）
			open OT,">$tsv_name" or die "Error! Cannot creat output file: $tsv_name\n";
		
			$hash{$libID}=1;
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
			if ($t[14]=~/病理诊断/){print OT "Pathology\t$t[14]\n";}
			print OT "Sample_Type\t$t[18]\n";
			print OT "Sample_Id\t$t[36]\n";#内部文库编号
			print OT "Sample_Source\t$t[15]\n";
			print OT "Sample_Collected_Date\t$t[16]\n";#取样日期
			print OT "Specimen_Received_Date\t$t[1]\n";#收样日期
			if ($t[14]=~/家族病史/){print OT "Fam_History\t$t[14]\n";}#家族史
			if ($t[14]=~/手术|化疗|用药/){print OT "Treatment_History\t$t[14]\n";}#治疗史
			if($t[14]=~/病理号/){
			my $pa_id=$t[14]; $pa_id=~s/.*病理号/病理号/;
			print OT "Pathology_id\t$pa_id\n";} #分子病理检测号，sumup表未提供该列
			print OT "Cancer_cell_ratio\t$t[19]\n";#肿瘤细胞比例，对应“癌组织含量”
		
			close OT;
		}
	}
	else {print "ERROR:$t[8] 分析项目未知,请确认!!!\n\n"}
}
close IN;

open IN2,"$ARGV[1]" or die "Error! Cannot open $ARGV[1]\n";
while (<IN2>){
	chomp;
	my $tsv_name=$_.".tsv";
	if (exists $hash{$_}){next;}
	else {`touch $tsv_name`} 
}
