#!/usr/bin/perl -w

use utf8;

die "perl $0 <sumup.lines>\n" unless (@ARGV ==1);

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
#	if ($t[9]=~/A01D|D53D/){$tsv_name="SampleInfo_".$tsv_name;}
	open OT,">$tsv_name" or die "Error! Cannot open $tsv_name\n";
	print "$t[8] analysis is $t[11]\n";
	
	if ($t[9]=~/A01D-5/){#oncoaim结直肠癌4基因货号匹配
		print OT "Name\t$t[7]\n";
		if($t[13]=~/^\s/){$t[13]="未提供";}
		print OT "Gender\t$t[13]\n";
		if($t[12]=~/^\s/){$t[12]="未提供";}
		print OT "Age\t$t[12]\n";
		if($t[14]=~/^\s/){$t[14]="未提供";}
		print OT "Diagnosis\t$t[14]\n";
		print OT "Treatment_History\t$t[14]\n";
		if ($t[14]=~/家族病史/){print OT "Fam_History\t$t[14]\n";}
		else {print OT "Fam_History\t未提供\n";}
		if($t[4]=~/^\s/){$t[4]="未提供";}
		print OT "Institution\t$t[4]\n";
		print OT "Sample_Type\t$t[18]\n";
#		if ($t[14]=~/样本来源/){print OT "sampling_location\t有\n";}
#		else{print OT "sampling_location\t未提供\n";}
		if($t[15]=~/^\s/){$t[15]="未提供";}
		print OT "Sampling_Location\t$t[15]\n";
		if ($t[14]=~/病理结果/){print OT "Pathological_Diagnosis\t$t[14]\n";}
		else{print OT "Pathological_Diagnosis\t未提供\n";}
		print OT "Sampling_Date\t$t[16]\n";
		print OT "Sample_Received_Date\t$t[1]\n";
		print OT "Analysis_Date\t$today\n";
	}
	
	elsif ($t[9]=~/A01D|D53D|H01D/){#ddCAPonTissue或ddCAPv2货号,甲状腺癌TC20
		print OT "#\n";
		print OT "Name\t$t[7]\n";
		if($t[13]=~/^\s/){$t[13]="未提供";}
		print OT "Gender\t$t[13]\n";
		if($t[12]=~/^\s/){$t[12]="未提供";}
		print OT "Age\t$t[12]\n";
		if($t[4]=~/^\s/){$t[4]="未提供";}
		print OT "Institution\t$t[4]\n";
		if($t[6]=~/\//){$t[6]="未提供";}
		print OT "Physician\t$t[6]\n";#不需要
		if($t[14]=~/^\s/){$t[14]="未提供";}
		print OT "Diagnosis\t$t[14]\n";
		if($t[16]=~/^\s/){$t[16]="未提供";}
		if(!$t[16]){$t[16]="未提供";}
#		print OT "Tumor_Staging_and_Grading\t$t[16]\n";
		print OT "Sampling_Date\t$t[16]\n";
		print OT "Sample_Type\t$t[18]\n";
#		if ($t[14]=~/样本来源/){print OT "Sampling_Location\t有\n";}#不需要
#		else{print OT "Sampling_Location\t未提供\n";}
		if($t[15]=~/^\s/){$t[15]="未提供";}
		print OT "Sampling_Location\t$t[15]\n";
#		print OT "Sampling_Date\t未提供\n";
		print OT "Sample_Shipping_Date\t$t[0]\n";
		print OT "Specimen_Received_Date\t$t[1]\n";
		if ($t[14]=~/家族病史/){print OT "Fam_History\t有\n";}#不需要
		else{print OT "Fam_History\t不确定\n";}
		print OT "Nuc_Iso_Date\t$t[30]\n";
		print OT "Nuc_Iso_Type\t$t[18]\n";
		$t[24]=~s/whole blood//;
		print OT "Nuc_Iso_Amount\t$t[24]\n";
		print OT "Nuc_Vol\t100\n";
		my $nuc_con=($t[26]/100);
		print OT "Nuc_Con\t$nuc_con\n";
		print OT "Nuc_Int_Evaluation\t好\n";
		print OT "Lib_Date\t$t[39]\n";
		print OT "Lib_Nuc_Amount\t$t[33]\n";
		print OT "Lib_Con\t$t[37]\n";
		print OT "Lib_Vol\t40\n";
		print OT "Insert_Size\t380\n";
		print OT "Analysis_Date\t$today\n";
		print OT "MolPathNo\t未提供\n";#分子病理检测号
		print OT "Medicine\t$t[14]\n";#用药史
		print OT "Anamnesis\t$t[14]\n";#既往病史
		print OT "Treatment_History\t$t[14]\n";#治疗史
		print OT "Pathological_Diagnosis\t$t[14]\n";#病理诊断
		
	}
	
	elsif($t[9]=~/G03D/){#CRC22和HBOC19货号
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
		print OT "Diagonosis\t$t[14]\n";
		if($t[16]=~/^\s/){$t[16]="未提供";}
		if(!$t[16]){$t[16]="未提供";}
		print OT "Sampling_Date\t$t[16]\n";
#		print OT "Tumor_Staging_and_Grading\t$t[16]\n";
		print OT "Sample_Type\t$t[18]\n";
#		if ($t[14]=~/样本来源/){print OT "Sampling_Location\t有\n";}
#		else{print OT "Sampling_Location\t未提供\n";}
		if($t[15]=~/^\s/){$t[15]="未提供";}
		print OT "Sampling_Location\t$t[15]\n";
#		print OT "Sampling_Date\t$t[0]\n";
		print OT "Specimen_Received_Date\t$t[1]\n";
		print OT "Fam_History\t不确定\n";
		print OT "Nuc_Iso_Date\t$t[30]\n";
		print OT "Nuc_Iso_Type\t$t[18]\n";
		$t[24]=~s/whole blood//;
		print OT "Nuc_Iso_Amount\t$t[24]\n";
		print OT "Nuc_Vol\t100\n";
		my $nuc_con=($t[26]/100);
		print OT "Nuc_Con\t$nuc_con\n";
		print OT "Nuc_Int_Evaluation\t好\n";
		print OT "Lib_Date\t$t[39]\n";
		print OT "Lib_Nuc_Amount\t$t[33]\n";
		print OT "Lib_Con\t$t[37]\n";
		print OT "Lib_Vol\t40\n";
		print OT "Insert_Size\t380\n";
		print OT "Analysis_Date\t$today\n";
	}
	elsif($t[11]=~/Riscare/){#Riskcare53/58内部检测代号
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
		print OT "Diagonosis\t$t[14]\n";
		if(!$t[16]){$t[16]="未提供";}
		if($t[16]=~/^\s/){$t[16]="未提供";}
#		print OT "Tumor_Staging_and_Grading\t$t[16]\n";
		print OT "Sampling_Date\t$t[16]\n";
		print OT "Sample_Type\t$t[18]\n";
		if($t[15]=~/^\s/){$t[15]="未提供";}
		print OT "Sampling_Location\t$t[15]\n";
#		if ($t[14]=~/样本来源/){print OT "Sampling_Location\t\n";}
#		else{print OT "Sampling_Location\t未提供\n";}
#		print OT "Sampling_Date\t$t[0]\n";
		print OT "Specimen_Received_Date\t$t[1]\n";
		print OT "Fam_History\t不确定\n";
		print OT "Nuc_Iso_Date\t$t[30]\n";
		print OT "Nuc_Iso_Type\t$t[18]\n";
		$t[24]=~s/whole blood//;
		print OT "Nuc_Iso_Amount\t$t[24]\n";
		print OT "Nuc_Vol\t100\n";
		my $nuc_con=($t[26]/100);
		print OT "Nuc_Con\t$nuc_con\n";
		print OT "Nuc_Int_Evaluation\t好\n";
		print OT "Lib_Date\t$t[39]\n";
		print OT "Lib_Nuc_Amount\t$t[33]\n";
		print OT "Lib_Con\t$t[37]\n";
		print OT "Lib_Vol\t40\n";
		print OT "Insert_Size\t380\n";
		print OT "Analysis_Date\t$today\n";
	}
	print "$t[8] 's tsv is done!\n";
	close OT;
}
close IN;
