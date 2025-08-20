#!/bin/bash

# Specify directories to be backed up here (separated by spaces). By default will back up the home directory. Note that ~ will not expand and function properly when placed in " ".
backupdirs=(~/) 

# Ask for user input, specify the location of backup drive(s)
backupdrive=()
add_drive() {
if [ -d $1 ]; then
	backupdrive+=($1)
else
	echo "Invalid path. Check that the drive is mounted and there are no typos."
	sleep 2
	echo "Enter the path of the drive you would like to backup to:"
	read drive
	add_drive $drive
fi
}

echo "Enter the path of the drive you would like to backup to:"
read drive
add_drive $drive

while :
do
	echo "Would you like to specify an additional backup drive? [Y/N]:"
	read choice
	if [ ${choice,,} = "y" ]; then
		echo "Enter the path of the drive you would like to backup to:"
		read drive
		add_drive $drive
	elif [ ${choice,,} = "n" ]; then
		break
	else
		:
	fi
done

if [[ -z ${backupdrive[@]} ]]; then
	exit 0
fi

# Save earlier specified directories as tar.gz files on the drive that is passed as an argument to the function. By default, the music directory will be excluded from the tar.gz archives and instead "synced" using rsync (The music directory is usually large and does not previous versions to be backed up.)
backingup() {
	backupfolder="$1/$(date '+%F at %H-%M')"
	mkdir "$backupfolder"
	for currentdir in ${backupdirs[@]}
	do
		echo "System backup on $currentdir"
		filename=$(echo $currentdir | sed -i s+/+_+g)
		if [ $currentdir = ~/ ]; then
			# The exclude option of tar needs to be an absolute path if the target path is absolute. If the target path is relative, the exclude option should also use a relative path... 
			# Also, if absolute paths are used, asis done in this script, there should be no trailing / after an excluded directory's path.
			cd ~/
			homedir=$(pwd)
			tar  -zcvf "$backupfolder/${filename}.tar.gz" --exclude=${homedir}/Music --exclude=${homedir}/.local/share/Trash --exclude=${homedir}/.cache $currentdir
		else
			tar -zcvf "$backupfolder/${filename}.tar.gz" $currentdir
		fi	
		sleep 2
	done

	echo "Syncing ~/Music"
	if [ ! -d ${1}/Music ]; then
		mkdir ${1}/Music
	fi
	rsync -rv ~/Music/ ${1}/Music
}

# Call the backup function for all drives specified earlier
for currentdrive in "${backupdrive[@]}"
do
	echo "Backing up on drive: $currentdrive"
	backingup "$currentdrive"
	echo "Backup on drive $currentdrive complete"
done

echo "All backups complete"
