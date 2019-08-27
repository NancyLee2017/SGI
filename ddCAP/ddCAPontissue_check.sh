work_path=$(pwd)
echo $work_path
mkdir Download
ls $work_path/*-M/*.report.filtered.tsv |perl -ne 'chomp;@a=split/\//;print "cp $_ ./Download/\ncp ./$a[-2]/$a[-2].cnv.tsv ./Download/\ncp ./$a[-2]/$a[-2].coverage.tsv ./Download/\ncp ./$a[-2]/$a[-2].sqm.json ./Download/\ncp ./$a[-2]/$a[-2].fusion_result.tsv ./Download/$a[-2].fusion_result.tsv\n"' >cp.sh
sh cp.sh
ls -1 $work_path/*-M/*report.filtered.tsv | perl -ne 'chomp;@t=split/\//;print"$t[-2]=$_\n";' >in.report.filtered.tsv.list
perl /home/hongyanli/script/ddCAP/combine_chope_tsv.noPASS.v3.2.7.pl in.report.filtered.tsv.list combined_tsv.xls 0.01 id_ontissue.list

#perl /home/hongyanli/script/ddCAP/find_CNV.pl id_ontissue.list $work_path

echo -e "EGFR exon20 indel\n" >KeySites_check.result
grep -P "\s20/" *-M/*.report.filtered.tsv |grep "EGFR" |grep "indel" >>KeySites_check.result
echo -e "\nEGFR exon19 indel\n" >>KeySites_check.result
grep -P "\s19/" *-M/*.report.filtered.tsv |grep "EGFR" |grep "indel" >>KeySites_check.result
echo -e "\nEGFR L858R\n" >>KeySites_check.result
grep -P "\s858\sL/R" *-M/*.report.filtered.tsv |grep "EGFR" >>KeySites_check.result
echo -e "\nEGFR T790M\n" >>KeySites_check.result
grep -P "\s790\sT/M" *-M/*.report.filtered.tsv |grep "EGFR" >>KeySites_check.result
echo -e "\nEGFR C797S\n" >>KeySites_check.result
grep -P "\s797\sC/S" *-M/*.report.filtered.tsv |grep "EGFR" >>KeySites_check.result
echo -e "\nEGFR L792\n" >>KeySites_check.result
grep -P "\s792\sL" *-M/*.report.filtered.tsv |grep "EGFR" >>KeySites_check.result
echo -e "\nEGFR G719S\n" >>KeySites_check.result
grep -P "\s719\sG/S" *-M/*.report.filtered.tsv |grep "EGFR" >>KeySites_check.result
echo -e "\nKRAS G12\n" >>KeySites_check.result
grep -P "\s12\sG/" *-M/*.report.filtered.tsv |grep "KRAS" >>KeySites_check.result
echo -e "\nKRAS G13\n" >>KeySites_check.result
grep -P "\s13\sG/" *-M/*.report.filtered.tsv |grep "KRAS" >>KeySites_check.result
echo -e "\nBRAF V600E\n" >>KeySites_check.result
grep -P "\s600\sV/E" *-M/*.report.filtered.tsv |grep "BRAF" >>KeySites_check.result



perl /data/home/hongyanli/script/ddCAP/find_denovo_fusion.pl in.report.filtered.tsv.list fusion2check.xls
