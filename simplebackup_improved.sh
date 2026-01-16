#!/bin/bash

# There will be errors using cp to copy on external drives with certain file systems.
# https://askubuntu.com/questions/1397519/cp-error-writing-file-too-large-cannot-copy-anything-more-than-4-3-gb

# Specify directories to be backed up here (separated by spaces). By default will back up the home directory. Note that ~ will not expand and function properly when placed in quotes " ".
backup_dirs=(~/) 

# Ask for user input, specify the location of backup drive(s)
backup_drives=()
add_drive() {
if [ -d $1 ]; then
	backup_drives+=($1)
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

if [[ -z ${backup_drives[@]} ]]; then
	exit 0
fi

archive_files=()
synced_dirs=()
backup_date="$(date '+%F at %H-%M')"
output_dirs=()

# Save earlier specified directories as tar.gz files on the drive that is passed as an argument to the function. By default, the user's music and video directories will be excluded from the tar.gz archives and instead "synced" using rsync (These directories are usually large and may not require previous versions to be backed up)
backingup() {
	output_dir="$1/$backup_date"
	output_dirs+=${output_dir}
	mkdir "$output_dir"
	for current_dir in ${backup_dirs[@]}
	do
		echo "System backup on $current_dir"
		filename=$(echo $current_dir | sed s+/+_+g)
		archive_path="${output_dir}/${filename}.tar.gz"
		if [ $current_dir = ~/ ]; then
			# The exclude option of tar needs to be an absolute path if the target path is absolute. If the target path is relative, the exclude option should also use a relative path... 
			# Also, if absolute paths are used, as is done in this script, there should be no trailing / after an excluded directory's path.
			cd ~/
			homedir=$(pwd)
			tar -zcvf "${archive_path}" --exclude=${homedir}/Music --exclude=${homedir}/.local/share/Trash --exclude=${homedir}/.cache $current_dir
			archive_files+=${archive_path}
		else
			tar -zcvf ${archive_path} $current_dir
			archive_files+=${archive_path}
		fi	
		sleep 2
	done

	echo "Syncing ~/Music"
	if [ ! -d ${1}/Music ]; then
		mkdir ${1}/Music
	fi
	rsync -rv --ignore-existing ~/Music/ ${1}/Music
	synced_dirs+=${1}/Music

	echo "Syncing ~/Videos"
	if [ ! -d ${1}/Videos ]; then
		mkdir ${1}/Videos
	fi
	rsync -rv --ignore-existing ~/Videos/ ${1}/Videos
	synced_dirs+=${1}/Videos
}

# Call the backup function for the first drive that was specified by the user. 
drive=${backup_drives[0]}
echo "Backing up on drive: $drive"
backingup "$drive"
echo "Backup on $drive complete"

# Copy archive files and synced directories that were created on the first drive over to the remaining drives.

for drive in ${backup_drives[@]:1}
do
	echo "Backing up on drive: $drive"

	for output_dir in "${output_dirs[@]}"
	do
		cp -r "$output_dir" "$drive"
	done

	for synced in ${synced_dirs[@]}
	do
		cp -r "$synced" "$drive"
	done
	echo "Backup on drive $drive complete"
done

echo "All backups complete"
