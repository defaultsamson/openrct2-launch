#!/bin/bash

dir="./OpenRCT2"
backup="./OpenRCT2Backup"

update() {
	url=$1
	echo "Updating: $url"
	temp=$(mktemp /tmp/openrct2.XXXXXXXX)

	echo "Downloading file..."
	wget $url -O $temp -q --show-progress

	# If the download failed, exit the program
	if [ $? -ne 0 ]; then
		echo "ERROR: File failed to dowload"
		if [ -f $temp ]; then
			rm $temp
		fi
		exit 1
	fi

	# Create a backup of the existing OpenRCT2 version
	if [ -d $dir ]; then
		if [ -d $backup ]; then
			rm -rf $backup
		fi
		mv $dir $backup
	fi

	tar xvzf $temp

	if [ $? -ne 0 ]; then
		echo "Failed to extract new version: !?"
		rm -rf $dir
		mv $backup $dir
		rm $temp
		exit 1
	fi

	rm $temp

	echo "Successfully downloaded version"
}

startgame() {
	savefile=""
	if [ $# -eq 0 ]; then
		savefile=$(ls -1 $HOME/.config/OpenRCT2/save/autosave/autosave*sv6 | tail -n 1)
		if [ $? -ne 0 ]; then
			echo "No autosave found. Please enter a save file."
			echo "Example: ./start.sh ./NewSave.sv6"
			exit 1
		fi
	else
		savefile=$1
	fi

	if [ ! -f "$savefile" ]; then
		echo "File doesn't exist: $1"
		exit 1
	fi

	echo "Starting game: $savefile"
	./OpenRCT2/openrct2-cli $savefile --headless
}

if [ $# -ge 1 ]; then
	if [[ $1 = *"tar.gz" ]]; then
		update $1
	elif [ $1 = "revert" ]; then
		if [ -d $backup ]; then
			if [ -d $dir ]; then
				rm -rf $dir
			fi
			mv $backup $dir
		else
			echo "No backup found"
		fi
	elif [ $1 = "help" ]; then
		echo "Please type up to two arguments."
		echo "Usage: ./update.sh <savefile> [url]"
		echo "   OR  ./update.sh auto [url]"
		echo "   OR  ./update.sh <url>"
		echo "   OR  to revert to the last working version of OpenRCT2"
		echo "       ./update.sh revert"
	elif [ $1 = "auto" ]; then
		if [ $# -ge 2 ]; then
			if [[ $2 = *"tar.gz" ]]; then
                		update $2
        		fi
		fi
		startgame
	else
		if [ $# -ge 2 ]; then
                        if [[ $2 = *"tar.gz" ]]; then
                                update $2
                        fi
                fi
		startgame $1
	fi
else
	# no parameters were passed, start by searching for new files
	newsave=$(ls -1 | egrep "^.*\.sv6$" | tail -n 1)
	if [ -f "$newsave" ]; then
		mkdir oldsaves
		mv $newsave "./oldsaves/"
		echo "Moved Save: $newsave"
		startgame "./oldsaves/$newsave"
	else
		startgame
	fi
fi
