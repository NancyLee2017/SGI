#!/bin/bash
. /etc/profile
PATH=/home/athurvagore/anaconda/envs/pipeline/bin:/home/athurvagore/anaconda/bin:/data/home/jiecui/software/jdk1.8.0_144/bin:/home/tinayuan/bin:/data/home/jiecui/software/jdk1.8.0_144/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/jvm/java-9-oracle/bin:/usr/lib/jvm/java-9-oracle/db/bin 
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

####################################################################
#Personal Config Part
Monitor="/data/SeqStore/nextseq_03"
Workspace="/home/tinayuan/Workspace/CLS/ddCAPctDNA_2019/"
Workers=32
####################################################################


#Pipeline Options: "ontissue","ddcapv3","thyroid"
Pipeline="ddcapv3"

#Function Part
function CheckSampleSheet(){
	if [ -f "$1/samples_file_${Pipeline}.txt" ];then
		if [ -f $2/samples_file_${Pipeline}.txt ];then
			echo "$2/samples_file_${Pipeline}.txt exist!"
		else
			cp $1/samples_file_${Pipeline}.txt $2
			cp $1/*id_${Pipeline}.list $2
		fi
		return 1
	else
		echo "$1/samples_file_${Pipeline}.txt not exist!"
		return 0
	fi
}


Sequencer=`echo $Monitor | cut -d / -f 4 | sed 's/_//' `
Log="$Workspace/dir_${Sequencer}.log"
echo
date
if [ `ps -ef |grep samples_file_${Pipeline}.txt | wc -l ` -gt 1 ];then
	echo "There is a samples_file_${Pipeline}.txt being anaylysed! "
	echo "--------------------------------------------------------------------------"
	exit
fi


if [ -f "$Log" ];then
	ls -F $Monitor |grep '/$' |sort >$Workspace/dir_change_${Sequencer}.log
	Diff=`diff $Workspace/dir_change_${Sequencer}.log  $Log |grep '<' |sed 's/<//g'| sed 's/\s//g'`
else
	echo "$Log not exist! Creat a new one!"
	ls -F $Monitor |grep '/$' |sort >$Log
fi

if [[ $Diff ]];then
	echo "Detected new folder: $Diff "
	for folder in $Diff
	do
		DataPath="$Monitor/$folder"
		SeqDate=`echo $folder | cut -d _ -f 1`
		AnalysisDir="$Workspace/${SeqDate}_${Sequencer}_PE148"
		if [ ! -d $AnalysisDir ];then
			mkdir $AnalysisDir
		fi
		cp /home/tinayuan/Workspace/CLS/ddCAPctDNA_2019/190817_nextseq03_PE148/luigi.cfg $AnalysisDir
		CheckSampleSheet $DataPath $AnalysisDir
		if [ $? -eq 1 ];then
			cd $AnalysisDir
			source /home/athurvagore/anaconda/bin/activate pipeline
#			which python
#			python --version
			python /home/tinayuan/Software/GitLab/ctdna-pipeline/main.py --module workflows DdcapUmiPePipeline --samples-file ${AnalysisDir}/samples_file_${Pipeline}.txt --output-dir $AnalysisDir --workers ${Workers} 1>log 2>err
			if [ $? -eq 0 ];then
				echo "Task finished!"
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
