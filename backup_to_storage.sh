#!/bin/bash

#set -x

CURRENTDATE=$(date +%d-%m-%Y)
FILENAME="backup-${CURRENTDATE}.tar.gz"

BACKUPSRC=/tmp/backup/
BACKUPDEST=/mnt/storage/backup/

DIRECTORIES=(/home/luca/Documents)

#if [[ $EUID -ne 0 ]]; then
#	echo
#	exit 1
#fi

if [ -d $BACKUPSRC ]; then
	:
else
	mkdir $BACKUPSRC
fi

if [ ! -d $BACKUPDEST ]; then
	mkdir -p $BACKUPDEST
fi      

for DIRECTORY in ${DIRECTORIES[@]}; do
	cp -a  $DIRECTORY $BACKUPSRC
done


cd $BACKUPSRC && tar --absolute-names --warning=no-file-changed -cpzf $FILENAME $BACKUPSRC 

mv $BACKUPSRC/$FILENAME $BACKUPDEST

if [ "$?" -eq 0 ]; then
	rm -rf $BACKUPSRC
	find $BACKUPDEST -name "*.tar.gz" -type f -mtime +10 -delete >> $BACKUPDEST/log.txt
else
	exit 1
fi

exit 0
