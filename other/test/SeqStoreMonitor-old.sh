#!/bin/bash
. /etc/profile

Monitor="/data/SeqStore/Nextseq_03_bcl"
Log="$Monitor/dir.log"

function CheckRTA() {
	cd $1
	if [ -f "RTAComplete.txt" ];then 
		echo "$1/RTAComplete.txt exists!"
		return 1
	else
		echo "$1/RTAComplete.txt does not exist!"
		return 0
	fi
}


function CheckSH() {
	SeqPath=$1
	cd $SeqPath
	if [ ! -f "demultiplex.sh" ];then
		perl /data/home/hongyanli/script/other/test/generate_demultiplex_script.v1.1.pl $SeqPath > $SeqPath/demultiplex.sh
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
	sh $1/demultiplex.sh
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
if [ -f "$Log" ];then
	ls -tF $Monitor |grep '/$' >$Monitor/dir_change.log
	Diff=`diff $Monitor/dir_change.log $Monitor/dir.log |grep '<' |sed 's/<//g'| sed 's/\s//g'`
	if [[ $Diff ]];then
		echo "Detected new folder: $Diff"
		for folder in $Diff
		do
			cd "$Monitor/$folder" && echo "change dir to: $Monitor/$folder"
			Path="$Monitor/$folder"
			CheckRTA $Path
			Res1=$?
			if [ $Res1 -eq 1 ];then
				CheckSH $Path
				Res2=$?
				if [ $Res2 -eq 1 ];then
					date +%T
					echo "Start demutilplexing..."
					DeMutilplex "$Monitor/$folder"
					if [ $? -eq 1 ];then
						cp $Monitor/dir_change.log $Monitor/dir.log
					fi
				else
					continue
				fi
			else
				continue
			fi
		done
	else 
		echo "No new folder!"
	fi
else
	ls -tF $Monitor |grep '/$' >$Log
	echo "No old log!"
	echo "Now creat a new log: $Log"
fi

echo "-------------------------------------------------------------------------------------------------"
