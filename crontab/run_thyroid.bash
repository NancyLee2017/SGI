#!/bin/bash
. /etc/profile
PATH=/home/athurvagore/anaconda/envs/pipeline/bin:/data/home/jiecui/software/jdk1.8.0_144/bin:/home/hongyanli/software/sendEmail-v1.56:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/jvm/java-9-oracle/bin:/usr/lib/jvm/java-9-oracle/db/bin
set -i

###Personal Config Part
Monitor="/data/SeqStore/nextseq_03"
Workspace="/home/hongyanli/workspace/CLS/Thyroid"
Pipeline="thyroid"
#Pipeline Options: "ontissue","ddcapv3","thyroid"
Workers=12

### Function Part

function CheckSampleSheet(){
	if [ -f "$1/samples_file_${Pipeline}.txt" ];then
		if [ -f $2/samples_file_${Pipeline}.txt ];then
			echo "$2/samples_file_${Pipeline}.txt exist!"
		else
			cp $1/samples_file_${Pipeline}.txt $2
		fi
		return 1
	else
		echo "$1/samples_file_${Pipeline}.txt not exist!"
		return 0
	fi
}

function CheckTSV(){
	if [ `ls $2/*tsv |wc -l` -gt 0 ];then
		echo "clinical info tsv exist"
		return 1
	else 
		if [ -f $1/sumup.line ];then
			cd $1
			perl /data/home/hongyanli/script/other/sample_info_generator_throid.pl $2/sumup.line
			continue
		else
			echo "$1/sumup.line not exist"
			continue
		fi
		return 0
	fi
}


Log="$Workspace/dir.log"
echo
date
if [ `ps -ef |grep samples_file_${Pipeline}.txt | wc -l ` -gt 1 ];then
	echo "There is a samples_file_${Pipeline}.txt being anaylysed! "
	echo "--------------------------------------------------------------------------"
	exit
fi


if [ -f "$Log" ];then
	ls -F $Monitor |grep '/$' |sort >$Workspace/dir_change.log
	Diff=`diff $Workspace/dir_change.log $Log |grep '<' |sed 's/<//g'| sed 's/\s//g'`
else
	echo "$Log not exist! Creat a new one!"
	ls -F $Monitor |grep '/$' |sort >$Log
fi

if [[ $Diff ]];then
	echo "Detected new folder: $Diff "
	for folder in $Diff
	do
		DataPath="$Monitor/$folder"
		SeqDate=`echo $Diff | cut -d _ -f 1`
		Sequencer=`echo $Monitor | cut -d / -f 4 | sed 's/_//' `
		AnalysisDir="$Workspace/${SeqDate}_${Sequencer}"
		if [ ! -d $AnalysisDir ];then
			mkdir $AnalysisDir
		fi

		CheckTSV $DataPath $AnalysisDir
		Res1=$?

		CheckSampleSheet $DataPath $AnalysisDir
		Res2=$?

		if [[ $Res1 -eq 1 ]] && [[ $Res2 -eq 1 ]];then
			cd $AnalysisDir
			source /home/athurvagore/anaconda/bin/activate pipeline
#			which python
#			python --version
			export LUIGI_CONFIG_PATH="/data/home/jiecui/software/git/pipeline-related-stuff/luigi_thyroid20_cls1.cfg"
			export JAVA_HOME='/data/home/jiecui/software/jdk1.8.0_144'
			export PATH="$JAVA_HOME/bin:$PATH"
			AnalysisDate=`date +%Y-%m-%d`
			python --version
			python /data/home/jiecui/software/git/ctdna-pipeline/main.py --module workflows Thyroid20SgiRjhPipeline --samples-file ${AnalysisDir}/samples_file_${Pipeline}.txt --output-dir $AnalysisDir --workers $Workers >${AnalysisDate}_logs.txt 2>&1
			if [ $? -eq 0 ];then
				echo "Task finished!"
				/data/home/hongyanli/software/sendEmail-v1.56/sendEmail -o tls=no -f wuyan2341199@163.com -t hongyan.li@singleragenomics.com -s smtp.163.com:25 -xu wuyan2341199@163.com -xp Lhy234ii99 -u "Work Finish!" -m " ${SeqDate}_${Sequencer} Thyroid v2 analysis finished! ${AnalysisDate} "
				echo "$folder" >>$Log
			fi
		fi
	done
	cat $Log |sort >$Workspace/dir.log.sort
	cp $Workspace/dir.log.sort $Log
	rm $Workspace/dir.log.sort
else
	echo "No new folder!"
fi
echo "---------------------------------------------------------------------------"
