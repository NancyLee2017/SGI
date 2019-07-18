#!/usr/bin/perl -w
#用于备份PGM下机的BRCA原始数据和workspace
use utf8;

die "perl $0 <id.list> <backup_record.xls>\n" unless (@ARGV ==2);
#输入文件必须有3列，第一列是LibID,第二列是IonXpressXXX,第三列填写原始bam文件的存储路径
open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT,">$ARGV[1]" or die "Error! Cannot open $ARGV[1] \n";

my $backup_seqstore='/mnt/Backup/CLS1/Project/Impact/SeqStore/';
my $backup_workspace='/mnt/Backup/CLS1/Project/Impact/workspace/';

while(<IN>){
	chomp;
	my @t=split/\t/;

	if ($t[0]=~/.+(-P)/){
	
		if($t[1]!~/IonXpress/){print "Warning: $t[0] missing bam_ID!\n";next;}#检查IonXpress编号是否存在
		if($t[2]!~/\/data\/SeqStore/){print "Warning: $t[0] missing Seqstore_path!\n";next;} #检查bam存储路径是否填写
		my $libID=$t[0];
		my $bam_ID=$t[1];
		my $path=$t[2];
		my $bam_name="$bam_ID"."*.bam";
		my $bam_path=`find $path -name "$bam_name"`;
		chomp $bam_path;#获得bam数据路径
		my $bai_path="$bam_path".".bai";
		my $run_folder=(split/\//,$bam_path)[-2];
		my $backup_folder="$backup_seqstore"."$run_folder";
		if (!-d "$backup_folder"){system("mkdir $backup_folder");}
		my $cp_bam=system("cp $bam_path $backup_folder");
		my $cp_bai=system("cp $bai_path $backup_folder");
		if ($cp_bam!=0){print "cp $bam_path error!\n"}
		if ($cp_bai!=0){print "cp $bai_path error!\n"}
		my $bam_backup_path=`find $backup_folder -name "$bam_name"`;
		chomp $bam_backup_path;
		
		my $workspace_name="*"."$libID"."*";
		my $workspace_find=`find /BRCAim_Luigi/workspace/ -type d -name "$workspace_name"`;
		my $workspace_path=(split/\n|\t/,$workspace_find)[-1];
		chomp $workspace_path;#获得BRCA分析结果路径
		
		my $cp_workspace=system("cp -R $workspace_path $backup_workspace");
		if ($cp_workspace!=0){print "cp $workspace_path error!\n"}
		
		my $sample_workspace=(split/\//,$workspace_path)[-1];
		my $workspace_backup_path="$backup_workspace"."$sample_workspace";#样本的workspace备份位置
		
		my $pdf_name_cn="*"."$libID"."*"."cn.pdf";#中文版
		my $pdf_name_en="*"."$libID"."*"."tsv.pdf";#英文版
		my $pdf_find_cn=`find /BRCAim_Luigi/report/ -type f -name "$pdf_name_cn"`;
		my $pdf_find_en=`find /BRCAim_Luigi/report/ -type f -name "$pdf_name_en"`;
		my $pdf_path_cn=(split/\n|\t/,$pdf_find_cn)[-1];
		my $pdf_path_en=(split/\n|\t/,$pdf_find_en)[-1];
		chomp $pdf_path_cn;#获得PDF中文报告路径
		chomp $pdf_path_en;#获得PDF英文报告路径
		my $cp_pdf_cn=system("cp -R $pdf_path_cn $workspace_backup_path");
		if ($cp_pdf_cn!=0){print "cp $pdf_path_cn error!\n"}
		my $cp_pdf_en=system("cp -R $pdf_path_en $workspace_backup_path");
		if ($cp_pdf_en!=0){print "cp $pdf_path_en error!\n"}
		print OT "$libID\t$bam_path\t$bam_backup_path\t$workspace_path\t$workspace_backup_path\t$pdf_path_cn\n";
	}
	else {print "$t[0] is not PGM data!";}
}