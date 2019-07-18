#!/usr/bin/perl -w
use strict;

die "perl $0 <ID.list> <out.xls> <onco|brca>\n" unless (@ARGV ==3);

open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT,">$ARGV[1]" or die "Error! Cannot open $ARGV[1] \n";

my @reports;
my %hash;

while(<IN>){
	chomp;
	my @t=split/\t/;
#处理PGM数据
	if ($t[0]=~/.+(-P)/){
	#PGM数据的输入list必须有3列，第一列是LibID,第二列是IonXpressXXX,第三列填写PGM_run的存储路径
		if($t[1]!~/IonXpress/){die "Error: Missing bam_ID!";}#检查IonXpress编号是否存在
		my $libID=$t[0];
		my $bam_ID=$t[1];
		my $path=$t[2];
		my $filename="$bam_ID"."*.bam";
		my $bam_path=`find $path -name "$filename"`;
		chomp $bam_path;#获得bam数据路径
		
		my $workspace_name="*"."$libID"."*";
		
		if($ARGV[2]=~/onco/){#对于oncoaim数据
			my $workspace_find=`find /OncoAim_PGM_denovo/workspace/ -type d -name "$workspace_name"`;
			my $workspace_path=(split/\n|\t/,$workspace_find)[-1];
			chomp $workspace_path;#获得OncoAim_PGM分析结果路径
		
			my $report_name="$libID"."*_variant_report.txt";
			my $report_find=`find /OncoAim_PGM_denovo/report/ -name "$report_name"`;
			my $report=(split/\n|\t/,$report_find)[-1];
			chomp $report;
			
			my $qc_info;#存放QC信息
		
			if ($report=~/_variant_report.txt/){#OncoAim DNA样本
				open TXT,"$report" or die "Open $report error!!\n";
				my $var_site=';';
				while (<TXT>){
					chomp;
					if($_=~/\*\*\w+\*\*\|/){
#						print "there is variant\n";
						my @v=split/\|/;
						my $gene=$v[0]; $gene=~s/\*//g;
						my $pos=$v[1];$pos=~s/\s+//g;
						my $ref=$v[2];$ref=~s/\s+//g;
						my $alt=$v[3];$alt=~s/\s+//g;
						my $freq=$v[4];$freq=~s/\s+//g;
						my $cosm=$v[5];$cosm=~s/\s+//g;
						my $cdna=$v[6];$cdna=~s/\s+//g;
						my $aa=$v[7];$aa=~s/\s+//g;
						my $type=$v[8];$type=~s/\s+//g;
						$var_site=join ",",$var_site,$gene,$pos,$ref,$alt,$freq,$cosm,$cdna,$aa,$type;
						$var_site="$var_site".";\t";
					}
					elsif($_=~/Median RD\| Uniformity/){
						my $temp=<TXT>;
						$qc_info=<TXT>;
						chomp $qc_info;
						$qc_info=~s/\s+//g;
						my @q=split/\|/,$qc_info;
						shift @q;
						$qc_info=join "\t",@q;
						$qc_info="$qc_info"."\t"."$var_site";
					}
				}close TXT;
			}
			else {
				my $fusion_report_name="Combinedfusionresults_report.txt";
				my $fusion_find=`find $workspace_path -name "$fusion_report_name"`;
				my $fusion_report=(split/\n|\t/,$fusion_find)[-1];
				chomp $fusion_report;
				if ($fusion_report=~/Combinedfusionresults_report.txt/){#OncoAimRNA样本
					open TXT,"$fusion_report" or die "Open $fusion_report error!!\n";
					my ($mapped_reads,$mapping_rate,$total_reads);
					my $fu_site=';';
					while (<TXT>){
						chomp;
						if($_=~/FUSION/){
							my @f=split/\t/;
							my $gene=$f[3];
							$gene=~s/,.+//;
							my $cosm=$f[2];
							$cosm=~s/,.+//;
							my $count=$f[4];
							$count=~s/,.+//;
							my $cp100k=$f[5];
							$cp100k=~s/,.+//;
							if ($cp100k>=25){$fu_site=join ",",$fu_site,$gene,$cosm,$count,$cp100k,";";}
							}
						elsif ($_=~/Total_mapped_reads/){my @a=split/\t/;$a[4]=~s/,.+//;$mapped_reads=$a[4];}
						elsif($_=~/Mapping_rate/){my @b=split/\t/;$b[4]=~s/,.+//;$mapping_rate=$b[4];}
					}close TXT;
					$total_reads=($mapped_reads/$mapping_rate)*100;
					$total_reads=sprintf "%d",$total_reads;
					$mapping_rate=sprintf "%.1f%%",$mapping_rate;
					$qc_info=join "\t",$total_reads,$mapped_reads,$mapping_rate,$fu_site;
				}
			}
			print OT "$libID\t$bam_path\t\t$workspace_path\t$qc_info\n";
		}
		
		elsif($ARGV[2]=~/brca|BRCA/){ #对于BRCA数据
			my $workspace_find=`find /BRCAim_Luigi/workspace/ -type d -name "$workspace_name"`;
			my $workspace_path=(split/\n|\t/,$workspace_find)[-1];
			chomp $workspace_path;#获得BRCA分析结果路径
			
			my $json_name="$workspace_name"."sqm\.json";
			my $json_path=`find $workspace_path -name "$json_name"`;
			chomp $json_path;#json文件名带全路径
			my @qc;#临时存放QC信息
			#以下提取json中的QC信息
			open JSON,"$json_path" or die "Open $json_path error!!\n";
			while (<JSON>){
				chomp;
				s/\{//g;
				s/\}//g;
				s/\"//g;
				s/\s//g;
				my @depth=split/,/;
				for (my $i=0;$i<=$#depth;$i++){
					if($depth[$i]=~/total_read_count/){my @temp=split/:/,$depth[$i];$qc[0]=$temp[1];next;}
					if($depth[$i]=~/mapped_read_count/){my @temp=split/:/,$depth[$i];$qc[1]=$temp[1];next;}
					if($depth[$i]=~/ontarget_read_count/){my @temp=split/:/,$depth[$i];$qc[3]=$temp[1];next;}
					if($depth[$i]=~/average_coverage/){my @temp=split/:/,$depth[$i];$qc[5]=$temp[1];next;}
					if($depth[$i]=~/uniformity/){my @temp=split/:/,$depth[$i];$qc[6]=$temp[1];next;}
					if($depth[$i]=~/average_amplicon_coverage/){my @temp=split/:/,$depth[$i];$qc[7]=$temp[1];next;}
					if($depth[$i]=~/fraction_target_covered/){my @temp=split/:/,$depth[$i];$qc[8]=$temp[1];next;}
					if($depth[$i]=~/fraction_known_sites_covered/){my @temp=split/:/,$depth[$i];$qc[9]=$temp[1];next;}
				}
			}close JSON;
			$qc[2]=$qc[1]/$qc[0]*100;
			$qc[2]=sprintf "%.2f%%",$qc[2];
			$qc[4]=$qc[3]/$qc[1]*100;
			$qc[4]=sprintf "%.2f%%",$qc[4];
			$qc[5]=sprintf "%d",$qc[5];
			$qc[6]=sprintf "%.2f%%",$qc[6]*100;
			$qc[7]=sprintf "%d",$qc[7];
			$qc[8]=sprintf "%.2f%%",$qc[8]*100;
			$qc[9]=sprintf "%.2f%%",$qc[9]*100;
			my $qc_info=join"\t",@qc;
			print OT "$libID\t$bam_path\t\t$workspace_path\t$qc_info\n";
		}
	}
	
#处理nextseq_02数据
	elsif ($t[0]=~/.+(-M)/){
		my $libID=$t[0];
		my $filename="$libID"."*_R1*.gz";
		my $gz_path=`find /media/SeqStore/nextseq_02/ -name "$filename"`;
		chomp $gz_path;
		my $workspace_name="*"."$libID"."*";
		
		if($ARGV[2]=~/onco/){#对于oncoaim数据
			my $workspace_find=`find /OncoAim_denovo/workspace/ -type d -name "$workspace_name"`;
			my $workspace_path=(split/\n|\t/,$workspace_find)[-1];
			chomp $workspace_path;#获得OncoAim_denovo分析结果路径
		
			my $report_name="$libID"."*_variant_report.txt";
			my $report_find=`find /OncoAim_denovo/report/ -name "$report_name"`;
			my $report=(split/\n|\t/,$report_find)[-1];
			chomp $report;
			
			my $qc_info;#存放QC信息
		
			if ($report=~/_variant_report.txt/){#OncoAim DNA样本
				open TXT,"$report" or die "Open $report error!!\n";
				my $var_site=';';
				while (<TXT>){
					chomp;
					if($_=~/\*\*\w+\*\*\|/){
#						print "there is variant\n";
						my @v=split/\|/;
						my $gene=$v[0]; $gene=~s/\*//g;
						my $pos=$v[1];$pos=~s/\s+//g;
						my $ref=$v[2];$ref=~s/\s+//g;
						my $alt=$v[3];$alt=~s/\s+//g;
						my $freq=$v[4];$freq=~s/\s+//g;
						my $cosm=$v[5];$cosm=~s/\s+//g;
						my $cdna=$v[6];$cdna=~s/\s+//g;
						my $aa=$v[7];$aa=~s/\s+//g;
						my $type=$v[8];$type=~s/\s+//g;
						$var_site=join ",",$var_site,$gene,$pos,$ref,$alt,$freq,$cosm,$cdna,$aa,$type;
						$var_site="$var_site".";\t";
					}
					elsif($_=~/Median RD\| Uniformity/){
						my $temp=<TXT>;
						$qc_info=<TXT>;
						chomp $qc_info;
						$qc_info=~s/\s+//g;
						my @q=split/\|/,$qc_info;
						shift @q;
						$qc_info=join "\t",@q;
						$qc_info="$qc_info"."\t"."$var_site";
					}
				}close TXT;
				
			}
			else {
				my $fusion_report_name="Combinedfusionresults_report.txt";
				my $fusion_find=`find $workspace_path -name "$fusion_report_name"`;
				my $fusion_report=(split/\n|\t/,$fusion_find)[-1];
				chomp $fusion_report;
				if ($fusion_report=~/Combinedfusionresults_report.txt/){#OncoAimRNA样本
					open TXT,"$fusion_report" or die "Open $fusion_report error!!\n";
					my ($mapped_reads,$mapping_rate,$total_reads);
					my $fu_site=';';
					while (<TXT>){
						chomp;
						if($_=~/FUSION/){
							my @f=split/\t/;
							my $gene=$f[3];
							$gene=~s/,.+//;
							my $cosm=$f[2];
							$cosm=~s/,.+//;
							my $count=$f[4];
							$count=~s/,.+//;
							my $cp100k=$f[5];
							$cp100k=~s/,.+//;
							if ($cp100k>=25){$fu_site=join ",",$fu_site,$gene,$cosm,$count,$cp100k,";";}
							}
						elsif ($_=~/Total_mapped_reads/){my @a=split/\t/;$a[4]=~s/,.+//;$mapped_reads=$a[4];}
						elsif($_=~/Mapping_rate/){my @b=split/\t/;$b[4]=~s/,.+//;$mapping_rate=$b[4];}
					}close TXT;
					$total_reads=($mapped_reads/$mapping_rate)*100;
					$total_reads=sprintf "%d",$total_reads;
					$mapping_rate=sprintf "%.1f%%",$mapping_rate;
					$qc_info=join "\t",$total_reads,$mapped_reads,$mapping_rate,$fu_site;
				}
			}
			print OT "$libID\t$gz_path\t\t$workspace_path\t$qc_info\n";
		}
		
		elsif($ARGV[2]=~/brca|BRCA/){ #对于BRCA数据
			my $workspace_find=`find /BRCAim_Luigi/workspace/ -type d -name "$workspace_name"`;
			my $workspace_path=(split/\n|\t/,$workspace_find)[-1];
			chomp $workspace_path;#获得BRCA分析结果路径
			
			my $json_name="$workspace_name"."sqm\.json";
			my $json_path=`find $workspace_path -name "$json_name"`;
			chomp $json_path;#json文件名带全路径
			my @qc;#临时存放QC信息
			#以下提取json中的QC信息
			open JSON,"$json_path" or die "Open $json_path error!!\n";
			while (<JSON>){
				chomp;
				s/\{//g;
				s/\}//g;
				s/\"//g;
				s/\s//g;
				my @depth=split/,/;
				for (my $i=0;$i<=$#depth;$i++){
					if($depth[$i]=~/total_read_count/){my @temp=split/:/,$depth[$i];$qc[0]=$temp[1];next;}
					if($depth[$i]=~/mapped_read_count/){my @temp=split/:/,$depth[$i];$qc[1]=$temp[1];next;}
					if($depth[$i]=~/ontarget_read_count/){my @temp=split/:/,$depth[$i];$qc[3]=$temp[1];next;}
					if($depth[$i]=~/average_coverage/){my @temp=split/:/,$depth[$i];$qc[5]=$temp[1];next;}
					if($depth[$i]=~/uniformity/){my @temp=split/:/,$depth[$i];$qc[6]=$temp[1];next;}
					if($depth[$i]=~/average_amplicon_coverage/){my @temp=split/:/,$depth[$i];$qc[7]=$temp[1];next;}
					if($depth[$i]=~/fraction_target_covered/){my @temp=split/:/,$depth[$i];$qc[8]=$temp[1];next;}
					if($depth[$i]=~/fraction_known_sites_covered/){my @temp=split/:/,$depth[$i];$qc[9]=$temp[1];next;}
				}
			}close JSON;
			$qc[2]=$qc[1]/$qc[0]*100;
			$qc[2]=sprintf "%.2f%%",$qc[2];
			$qc[4]=$qc[3]/$qc[1]*100;
			$qc[4]=sprintf "%.2f%%",$qc[4];
			$qc[5]=sprintf "%d",$qc[5];
			$qc[6]=sprintf "%.2f%%",$qc[6]*100;
			$qc[7]=sprintf "%d",$qc[7];
			$qc[8]=sprintf "%.2f%%",$qc[8]*100;
			$qc[9]=sprintf "%.2f%%",$qc[9]*100;
			my $qc_info=join"\t",@qc;
			print OT "$libID\t$gz_path\t\t$workspace_path\t$qc_info\n";
		}
	}
}
close IN;
close OT;