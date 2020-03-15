#!/bin/bash
# dvrDroid_0.3.1-release.sh
# 2020 (C) Nikolas A. Wagner
# License: GNU GPLv3

# Build_0001

	#This program is free software: you can redistribute it and/or modify
	#it under the terms of the GNU General Public License as published by
	#the Free Software Foundation, either version 3 of the License, or
	#(at your option) any later version.

	#This program is distributed in the hope that it will be useful,
	#but WITHOUT ANY WARRANTY; without even the implied warranty of
	#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	#GNU General Public License for more details.

	#You should have received a copy of the GNU General Public License
	#along with this program.  If not, see <https://www.gnu.org/licenses/>.


#                                          -- Purpose --
# Record a device's screen pseudo-continuously with adb's 'screenrecord' command! As little as 0.5s delay between recordings!
#                                          --  -  ---  -  --

# kill script if script would have root privileges
if [ "$EUID" = 0 ]; then echo "You cannot run script this with root privileges!"; kill $( jobs -p ) 2>/dev/null || exit 1; fi

build="0001"; scriptTitle="dvrDroid"

# make sure SIGINT always works even in presence of infinite loops
exitScript() {
	trap - SIGINT SIGTERM SIGTERM # clear the trap

	#CMD_rmALL # remove temporary files
	IFS=$ORIGINAL_IFS # set original IFS

	kill -- -$$ # Send SIGTERM to child/sub processes
	kill $( jobs -p ) # kill any remaining processes
}; trap exitScript SIGINT SIGTERM # set trap

INIT(){
	waitMessage="-- waiting for device --"; stopInfo="Use CTRL-C"
	UIsep_title="------------------"; COLS=$(tput cols)
	mkdir ~/screenRecordings_Android

	anim1=( # doge so like
	"                        " "W                       " "Wo                      " "Wow                     " "Wow!                    " "Wow!                    " "Wow!                    "
	"Wow!                    " "Wow!                    " "Wow!                    " "Wow!                    " "Wow! V                  " "Wow! Ve                 "
	"Wow! Ver                " "Wow! Very               " "Wow! Very               " "Wow! Very l             " "Wow! Very lo            " "Wow! Very loa           "
	"Wow! Very load          " "Wow! Very loadi         " "Wow! Very loadin        " "Wow! Very loading       " "Wow! Very loading.      " "Wow! Very loading..     "
	"Wow! Very loading...    " "Wow! Very loading....   " "Wow! Very loading.....  " "Wow! Very loading...... " "Wow! Very loading......." "Wow! Very loading......." "Wow! Very loading......."
	"Wow! Very loading...... " "Wow! Very loading.....  " "Wow! Very loading....   " "Wow! Very loading...    " "Wow! Very loading..     " "Wow! Very loading.      "
	"Wow! Very loading       " "Wow! Very loading.      " "Wow! Very loading..     " "Wow! Very loading...    " "Wow! Very loading....   " "Wow! Very loading.....  "
	"Wow! Very loading...... " "Wow! Very loading......." "Wow! Very loading......." "Wow! Very loading......." "Wow! Very loading......." "Wow! Very loading......." "Wow! Very loading......."
	)
	anim2=( # simple / professional
	"oooooooooooooooooooooooo"
	"ooooooooooo00ooooooooooo" "oooooooooo0oo0oooooooooo" "ooooooooo0oooo0ooooooooo" "oooooooo0oooooo0oooooooo" "ooooooo0oooooooo0ooooooo" "oooooo0oooooooooo0oooooo"
	"ooooo0oooooooooooo0ooooo" "oooo0oooooooooooooo0oooo" "ooo0oooooooooooooooo0ooo" "oo0oooooooooooooooooo0oo" "o0oooooooooooooooooooo0o" "0oooooooooooooooooooooo0"
	"oooooooooooooooooooooooo" "0oooooooooooooooooooooo0" "o0oooooooooooooooooooo0o" "oo0oooooooooooooooooo0oo" "ooo0oooooooooooooooo0ooo" "ooo0oooooooooooooooo0ooo"
	"oooo0oooooooooooooo0oooo" "ooooo0oooooooooooo0ooooo" "oooooo0oooooooooo0oooooo" "ooooooo0oooooooo0ooooooo" "oooooooo0oooooo0oooooooo" "ooooooooo0oooo0ooooooooo"
	"oooooooooo0oo0oooooooooo" "ooooooooooo00ooooooooooo" "oooooooooooooooooooooooo"
	)
	anim3=( # matrix
	"110010110110101100010100" "010010110111001001011110" "100110100011000110111011" "100110010010001100110110" "100110010111001101101101" "101101101101011101010101"
	"100011011101001110011001" "011010110001101101110110" "101010010101110100100010" "100111010000110101101011" "101100001111010111101001" "010101010100010101010100"
	"101011011101001110011001" "011010110001101101110110" "101010010101100000100011" "100111010000110101101011" "101100001111010111101001" "010101010100010101010100"
	"110010110110101100010100" "010010110111001001011110" "100110100011000110111010" "100110010010001100110110" "100110010111001101101101" "101101101101011101010101"
	"101011011101001110011001" "010111010101110110101001" "101010010101110100100011" "100111010000110101101011" "101100001111010111101001" "010101010100010101010100"
	"110010110110101100010100" "010010110111001001011110" "100110100011000010111011" "100110010010001100110110" "100110010111001101101101" "101101101101011101010101"
	"110010110110101100010100" "010010110111001001011110" "100110100011000110111011" "100110010010001100110110" "100110010111001101101101" "101101101101011101010101"
	"101011011101001110011001" "010111010101110110101001" "101010010101110000100010" "100111010000110101101011" "101100001111010111101001" "010101010100010101010100"
	)

	printTitle(){
		printf "\n%*s\n" $((COLS/2)) "$scriptTitle"
		printf "%*s\n\n\n" $((COLS/2)) "$UIsep_title"
	}

	if figlet -t -w 0 -F metal "TEST FULL FIG"; then
		stopInfo_f=$(figlet -c -F metal -t "Use CTRL-C to stop")
		printTitle(){
			figlet -c -F border -F gay -t "$scriptTitle"
		}
	elif figlet -w 0 -f small "TEST SIMPLE FIG"; then
		stopInfo_f=$(figlet -c -w $COLS -f small "Use CTRL-C to stop")
		printTitle(){
			figlet -c -w $COLS "$scriptTitle"
		}
	else
		stopInfo_f="$stopInfo"
		printTitle(){
			printf "\n%*s\n" $((COLS/2)) "$scriptTitle"
			printf "%*s\n\n\n" $((COLS/2)) "$UIsep_title"
		}
	fi
}; INIT

CMD_communicate(){ adb -d shell exit 2>/dev/null; }

screenDVR(){
	read -r -p 'Enter the file path (or just drag the folder itself) of where you want to save the video sequences.. ' savePath
	if [ "$savePath" = "" ]; then 
		printf "\nDefaulting to ~/screenRecordings_Android/\n"
		cd ~/screenRecordings_Android
	else
		cd $savePath
	fi

	adbWAIT

	# remove all files on device containing 'rec.'
	adb -d shell rm -f *"/sdcard/rec."*

	# make sure SIGINT always works even in presence of infinite loops
	exitScriptDVR() {
		trap - SIGINT SIGTERM SIGTERM # clear the trap
		tput cnorm
		adb -d shell echo \04; wait

		extract

		# remove all files in dir /sdcard/ beginning with 'rec.'
		adb -d shell rm -f *"/sdcard/rec."*; wait
		wait; exit
	}; trap exitScriptDVR SIGINT SIGTERM # set trap

	extract(){
		# kill script if script would have root privileges
		if [ "$EUID" = 0 ]; then echo "You cannot run script this with root privileges!"; kill $( jobs -p ) 2>/dev/null || exit 1; fi

		printf "\n%*s\n" $((0)) "Extracting.. $fileName .. to your computer!"
		wait && adb pull sdcard/$fileName || { adbWAIT && adb pull sdcard/$fileName 1>/dev/null; }
	}

	record(){
		# kill script if script would have root privileges
		if [ "$EUID" = 0 ]; then echo "You cannot run script this with root privileges!"; kill $( jobs -p ) 2>/dev/null || exit 1; fi

		printf "$stopInfo_f"
		while true; do
			tStamp="$(date +'%Hh%Mm%Ss')"
			fileName="rec.$tStamp.$$.mp4"

			printf "\n%*s\n\n" $((0)) "Starting new recording: $fileName"
			adb -d shell screenrecord /sdcard/$fileName || { adbWAIT; wait; extract; }

			# running extract in a sub-process means only 0.5 seconds or so of delay between videos
			wait; extract &
		done
	}
	record && wait && exitScriptDVR
}

# update the script on status of adb connection and call waiting function until it is ready
adbWAIT(){
	COLS=$(tput cols)
	if (CMD_communicate); then
		export deviceConnect="true"
	else
		tput civis
		printf "\n\n%*s\n" $((COLS/2)) "$waitMessage"
		{ sleep 3; printf "        Ensure only one device is connected!"; } & { 
			until (CMD_communicate); do
				waiting
			done
		}
		tput cnorm
		printf "\r%*s\n\n" $((COLS/2)) "!Device Connected!   "
	fi
}

# show the waiting animation
waiting(){
	tput civis
	for i in "${anim3[@]}" # <<-- change my number to change my animation (1, 2, or 3)!
	do
		printf "\r%*s" $((COLS/2)) "$i"
		sleep 0.045
	done
}

clear; printTitle
(screenDVR) #&& printf "\ncontinue main loop\n"
exit