#!/bin/bash
. /etc/profile
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

Monitor="/mnt/rawdata/NextSeq500-2"
Seqstore="/data/SeqStore/nextseq_02"
Log="$Seqstore/dir.log"
Input="CLS.seqinfo.xls"

function CheckRTA() {
	if [ -f "$1/RTAComplete.txt" ];then 
		echo "$1/RTAComplete.txt exists!"
		return 1
	else
		echo "$1/RTAComplete.txt does not exist!"
		return 0
	fi
}


function CheckSH() {
	SeqPath=$2
	cd $SeqPath
	if [ ! -f "demultiplex.sh" ];then
		perl /data/home/hongyanli/script/crontab/generate_demultiplex_script.auto.pl $1 > $SeqPath/demultiplex.sh
		if [ `cat "$SeqPath/demultiplex.sh" |wc -l` -ge 3 ];then 
			echo "Creat $SeqPath/demultiplex.sh"
			return 1
		else
			echo "$SeqPath/demultiplex.sh is empty!"
			rm "$SeqPath/demultiplex.sh"
			return 0
		fi
	else
		if [ `cat "$SeqPath/demultiplex.sh" |wc -l` -ge 3 ];then 
			echo "$SeqPath/demultiplex.sh exists!"
			return 1
		else
			echo "$SeqPath/demultiplex.sh is empty!"
			rm "$SeqPath/demultiplex.sh"
			return 0
		fi
	fi
}

function DeMutilplex() {
	cd $1
	if [ -f $1/demultiplex.sh.o ];then
		echo "$1 demultiplexing may be done before!"
	else
		sh $1/demultiplex.sh
#	ls -l $1/demultiplex.sh #for test only
	fi

	if [ $? -eq 0 ];then
		date +%T
		echo "$1 demultiplexing is done!"
		return 1
	else
		date +%T
		echo "$1 demultiplexing ERROR!"
		return 0
	fi
}

date
if [ `ps -ef | grep "bcl2fastq" | wc -l` -gt 1 ];then
	echo "Bcl2fastq is running now!"
	echo " "
	exit
fi

if [ -f "$Log" ];then
	ls -F $Monitor |grep '/$' |sort >$Seqstore/dir_change.log
	Diff=`diff $Seqstore/dir_change.log $Seqstore/dir.log |grep '<' |sed 's/<//g'| sed 's/\s//g'`
	if [[ $Diff ]];then
		echo "Detected new folder:"
		echo "$Diff"
		for folder in $Diff
		do
			Path1="$Monitor/$folder"
			Path2="$Seqstore/$folder"
			SeqDate=`echo $folder | cut -d _ -f 1`
			Sequencer=`echo $Seqstore | cut -d / -f 4 | sed 's/_//' `

			if [ ! -d "$Seqstore/$folder" ];then
				echo "Warning: $Seqstore/$folder not exist, make it now!"
				mkdir $Seqstore/$folder
				chmod 777 $Seqstore/$folder
				continue;
			fi

			if [ -f "$Path2/demultiplex.sh.o" ];then
				echo "Warning: $Seqstore/$folder  This folder is demultiplexed!"
				echo "$folder" >>$Seqstore/dir.log
				continue
			fi
			
			if [ -f "$Path2/$Input" ];then
				cd $Path2 
				perl /home/hongyanli/script/crontab/Do_SampleSheet_dumutiplexing.pl ${Path2}/${Input}
			fi
			
			if [ -f "$Path2/ACE.seqinfo.${SeqDate}_${Sequencer}.xls" ];then
				cd $Path2
				perl /data/home/tinayuan/bin/ACE/generate_files_4ACE_run.v2.2.pl "$Path2/ACE.seqinfo.${SeqDate}_${Sequencer}.xls" "${SeqDate}_${Sequencer}"
			fi

			if [[ ! -f "$Path2/$Input" ]] && [[ ! -f "$Path2/ACE.seqinfo.${SeqDate}_${Sequencer}.xls" ]];then
				echo "Warning: No sequencer_info file under $Seqstore/$folder "
#				continue
			fi

			CheckRTA $Path1
			Res1=$?
			if [ $Res1 -eq 1 ];then
				CheckSH $Path1 $Path2
				Res2=$?
				if [ $Res2 -eq 1 ];then
					date +%T
					echo "Start demutilplexing..."
					DeMutilplex $Path2
					if [ $? -eq 1 ];then
						echo "$Path2 demutilplexing successed!"
						echo "$folder" >>$Seqstore/dir.log
#						chmod -R 777 $Seqstore/$folder/
						cd $Seqstore/$folder
						if [ `ls -1 $Path2 |grep 'ACE' |wc -l ` gt 1 ];then
							echo "There are ACE samples in $Path2"	
						fi
						perl /data/home/hongyanli/script/crontab/sequencer_info_analysis.pl $Input $Path2
					fi
				else
					continue
				fi
			else
				continue
			fi
		done
		cat $Log |sort >$Seqstore/dir.log.sort
		cp $Seqstore/dir.log.sort $Seqstore/dir.log
		rm $Seqstore/dir.log.sort
	else 
		echo "No new folder!"
	fi
else
	ls -F $Monitor |grep '/$' |sort >$Log
	echo "No old log!"
	echo "Now creat a new log: $Log"
fi

echo "-------------------------------------------------------------------------------------------------"
