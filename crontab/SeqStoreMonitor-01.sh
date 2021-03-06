#!/bin/bash
. /etc/profile
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

Monitor="/mnt/rawdata/NextSeq500-1"
Seqstore="/data/SeqStore/nextseq_01"
Log="$Seqstore/dir.log"

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
		perl /data/home/hongyanli/script/other/test/generate_demultiplex_script.v2.1.pl $1 > $SeqPath/demultiplex.sh
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
	if [-f $1/demultiplex.sh.o];then
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
#	cat $Log |uniq |sort >$Log
	Diff=`diff $Seqstore/dir_change.log $Seqstore/dir.log |grep '<' |sed 's/<//g'| sed 's/\s//g'`
	if [[ $Diff ]];then
		echo "Detected new folder:"
		echo "$Diff"
		for folder in $Diff
		do
			if [ ! -d "$Seqstore/$folder" ];then
				echo "Warning: $Seqstore/$folder not exist, make it now!"
				mkdir $Seqstore/$folder
				chmod 777 $Seqstore/$folder
				continue;
			fi

			if [ -f "$Seqstore/$folder/demultiplex.sh.o" ];then
				echo "Warning: $Seqstore/$folder  This folder is demultiplexed!"
				echo "$folder" >>$Seqstore/dir.log
				continue
			fi

			Path1="$Monitor/$folder"
			Path2="$Seqstore/$folder"
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
				#		echo "$Path2 demutilplexing successed!"
						echo "$folder" >>$Seqstore/dir.log
				#		chmod -R 777 $Seqstore/$folder/
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
