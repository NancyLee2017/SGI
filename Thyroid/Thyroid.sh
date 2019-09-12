date=`date +%Y-%m-%d`
sever=`hostname`
my_home=/home/hongyanli

work_path=$(pwd)
ls $work_path/*-M/*report.clinsig.filtered.tsv >report.clinsig.filtered.tsv.list
ls $work_path/*-M/*sqm.json >dup.json.list
ls $work_path/*-M/*dedup*.json >dedup.json.list
perl $my_home/script/Thyroid/summary_thyroid.pl report.clinsig.filtered.tsv.list Thyroid_${date}_variant.xls
perl $my_home/script/ddCAP/qc_json_ontissue.pl dup.json.list Thyroid_${date}_QCdup.xls
perl $my_home/script/ddCAP/qc_json_ontissue.pl dedup.json.list Thyroid_${date}_QCdedup.xls
perl $my_home/script/Thyroid/write2excel.pl Thyroid_${date}_variant.xls Thyroid_${date}_QCdup.xls Thyroid_${date}_QCdedup.xls Thyroid_${date}_combined_results.xls

#SRJ summary 
mkdir $work_path/variant_summary
cd $work_path/variant_summary
summary_path=$(pwd)
/data/home/jiecui/software/anaconda2/envs/py36/bin/python /data/home/jiecui/workspace/SGI/thyroidv2/bin/get_sqv_runall.py $work_path $summary_path thyroid20SgiRjh

