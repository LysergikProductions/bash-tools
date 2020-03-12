#!/bin/bash
# AndroidInstall_1.2.0-release.sh
# 2020 (C) Nikolas A. Wagner
# License: GNU GPLv3

# Build_0286

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
# Simplify the process of installing and make it as convenient as possible to install builds on Android devices, via Android Debug Bridge
#                                          --  -  ---  -  --

# kill script if script would have root privileges
if [ "$EUID" = 0 ]; then echo "You cannot run script this with root privileges!"; kill $( jobs -p ) 2>/dev/null || exit 1; fi

# remove any pre-existing tmp files, log all system variables at script execution, then check that file still exists
rm -f /tmp/variables.before /tmp/variables.after /tmp/usrIPdata.xml /tmp/devIPdata.xml
if ! ( set -o posix ; set ) >/tmp/variables.before; then kill $( jobs -p ) 2>/dev/null || exit 1; fi
if ! file /tmp/variables.before 1>/dev/null; then kill $( jobs -p ) 2>/dev/null || exit 1; fi

# some global variables
scriptStartDate=""; scriptStartDate=$(date)

build="0286"; scriptVersion=1.2.0-release; author="Nikolas A. Wagner"; license="GNU GPLv3"
scriptTitleDEF="StoicDroid"; scriptPrefix="AndroidInstall_"; scriptFileName=$(basename "$0")
adbVersion=$(adb version); bashVersion=${BASH_VERSION}; currentVersion="_version errorGettingProperties.txt"

# studio specific variables
fireAPPS=( "GO BACK" "option1" "option2" "option3" "option4" "option5" "option6" "option7" )
studio=""; gitName="Android-Installer"

# make sure SIGINT always works even in presence of infinite loops
exitScript(){
	trap - SIGINT SIGTERM SIGTERM # clear the trap

	CMD_rmALL # remove temporary files
	IFS=$ORIGINAL_IFS # set original IFS

	kill -- -$$ # Send SIGTERM to child/sub processes
	kill $( jobs -p ) # kill any remaining processes
}; trap exitScript SIGINT SIGTERM # set trap

help(){
	printf "  Help Page\n\n"
	printf " - OPTIONS -\n\n"
	printf "  -c      also [show-c]; show the copyright & license information\n"
	printf "  -l      also [show-l]; show the copyright & license information\n"
	printf "  -u      also [--update]; run the script in update mode (not working yet)\n"
	printf "  -q      also [--quiet]; run the script in quiet mode\n"
	printf "  -s      also [--safe]; run the script in safe mode\n"
	printf "  -d      also [--debug]; run the script in debug mode. Add a -v to increase verbosity!\n\n"
	printf "  -t      also [--top]; show device CPU and RAM usage\n"
	printf "  -h      also [--help]; show this information\n\n"
	printf " - INSTRUCTIONS -\n\nSkip the OBB step using one of the following:\n\n  na, 0, .      OBB not applicable\n"
	printf "  fire          Amazon build\n\n"
}

updateIP(){
	update_IPdata 2>/dev/null
	parse_IPdata
	deviceIP="$devIP"
	deviceLOC="$devCity, $devRegion, $devCountry"
}

update_IPdata(){
	if [ "$verbose" = 1 ]; then printf "\n\nUpdating IP DATA\n\n"; fi

	rm -f >/tmp/usrIPdata.xml >/tmp/devIPdata.xml

	usrIP=$(timeout 3s curl https://ipinfo.io/ip) || usrIP="timeout or error"
	devIP=$(timeout 3s adb -d shell curl https://ipinfo.io/ip)|| devIP="timeout"

	usrIP_XML=$(timeout 3s curl https://freegeoip.app/xml/$usrIP >/tmp/usrIPdata.xml)
	devIP_XML=$(timeout 3s adb -d shell curl https://freegeoip.app/xml/$devIP >/tmp/devIPdata.xml)
}

parse_IPdata(){
	if [ "$verbose" = 1 ]; then printf "\n\nParsing IP DATA\n\n"; fi

	readXML(){
		IFS=\>
		read -d \< ENTITY CONTENT
		ret=$?
		TAG_NAME="${ENTITY%% *}"
		ATTRIBUTES="${ENTITY#* }"
		return $ret
	}

	parse_usrIP_XML(){
		if [[ "$TAG_NAME" = "IP" ]] ; then usrIP=$CONTENT; fi
		if [[ "$TAG_NAME" = "CountryName" ]] ; then usrCountry=$CONTENT; fi
		if [[ "$TAG_NAME" = "RegionName" ]] ; then usrRegion=$CONTENT; fi
		if [[ "$TAG_NAME" = "City" ]] ; then usrCity=$CONTENT; fi
	}

	parse_devIP_XML(){
		if [[ "$TAG_NAME" = "IP" ]] ; then devIP=$CONTENT; fi
		if [[ "$TAG_NAME" = "CountryName" ]] ; then devCountry=$CONTENT; fi
		if [[ "$TAG_NAME" = "RegionName" ]] ; then devRegion=$CONTENT; fi
		if [[ "$TAG_NAME" = "City" ]] ; then devCity=$CONTENT; fi
	}

	while readXML; do
		parse_usrIP_XML
	done < /tmp/usrIPdata.xml

	while readXML; do
		parse_devIP_XML
	done < /tmp/devIPdata.xml

	IFS=$ORIGINAL_IFS
}

getBitWidth(){
	bitWidth_raw=$(adb -d shell getprop ro.product.cpu.abi)
	if [ "$bitWidth_raw" = "" ]; then
		bitWidth=""
	elif [ "$bitWidth_raw" = "" ]; then
		bitWidth=""
	else
		bitWidth="under construction"
		echo "$bitWidth_raw"
	fi
}

# allow user to see the copyright, license, or the help page without running the script
COLS=$(tput cols)
if [[ "$*" == *"show-c"* ]] || [[ "$*" == *"-c"* ]] || [[ "$*" == *"show-l"* ]] || [[ "$*" == *"-l"* ]]; then
	printf "\n2020 © Nikolas A. Wagner\nGNU GPLv3: https://www.gnu.org/licenses/\n"
	if [[ "$*" == *"--help"* ]] || [[ "$*" == *"-h"* ]]; then echo; help; exit; fi
fi

# if user didn't choose -c or -l at all, then check..
if [[ "$*" == *"--help"* ]] || [[ "$*" == *"-h"* ]]; then echo; help; exit
elif [[ "$*" == *"--top"* ]] || [[ "$*" == *"-t"* ]]; then
	clear
	if adb -d shell exit; then
		updateIP
		{ sleep 0.5; while (trap exitScript SIGINT SIGTERM)
			do
				printf "\n%*s\n" $((COLS/2)) "Device Location: $deviceLOC"
				sleep 1.99
			done
		} & adb -d shell top -d 2 -m 5 -o %MEM -o %CPU -o CMDLINE -s 1 || exit
	else exit 1; fi
fi

# if user did not choose any above options, then check for script mode flags
#if [[ "$*" == *"--update"* ]] || [[ "$*" == *"-u"* ]]; then UNINSTALL="false"; OBBdone="true"; fi
if [[ "$*" == *"--safe"* ]] || [[ "$*" == *"-s"* ]]; then sMode="true"; else sMode="false"; fi
if [[ "$*" == *"--debug"* ]] || [[ "$*" == *"-d"* ]]; then
	verbose=1; qMode="false"; sMode="false"
	if [[ "$*" == *"-v"* ]] || [[ "$*" == *"--verbose"* ]]; then verbose=2; fi
elif [[ "$*" == *"--quiet"* ]] || [[ "$*" == *"-q"* ]]; then verbose=0; qMode="true"
else verbose=0; qMode="false"; fi

# prepare script for running the MAIN function
INIT(){
	echo "Initializing.." &

	# some default/starting variables values
	loopFromError="false"; upToDate="error checking version"; errorMessage=" ..no error is saved here.. "
	deviceConnect="true"; OBBdone="false"; APKdone="false"; UNINSTALL="true"; errExec="false"

	# text-UI elements and related variables
	UIsep_title="------------------"; UIsep_head="-----------------------------------------"; UIsep_err0="--------------------------------"
	waitMessage="-- waiting for device --"; OBBquest="OBB"; APKquest="APK"; showIP="true"; OBBinfo=""

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

	if [ "$qMode" = "false" ]; then
		OBBquest="Drag OBB and press enter:"
		OBBinfo="\nSkip? Type: na, 0, or .\nAmazon? Type: fire\n\n"

		APKquest="Drag APK anywhere here:"

		if [ "$verbose" = 1 ]; then printf "\nTesting for figlet compatibility..\n"; sleep 1; fi
		if figlet -t -w 0 -F metal "TEST FULL FIG"; then
			if [ "$verbose" = 0 ]; then clear; fi
			echo "Initializing.." &
			oops=$(figlet -F metal -t "Oops!"); if [ "$verbose" = 0 ]; then clear; fi
			printTitle(){
				figlet -F border -F gay -t "$scriptTitle"
			}
		elif figlet -w 0 -f small "TEST SIMPLE FIG"; then
			if [ "$verbose" = 0 ]; then clear; fi
			echo "Initializing.." &
			oops=$(figlet -f -w $COLS small "Oops!"); if [ "$verbose" = 0 ]; then clear; fi
			printTitle(){
				figlet -w $COLS "$scriptTitle"
			}
		else
			oops="Oops!"
			printTitle(){
				printf "\n%*s\n" $((COLS/2)) "$scriptTitle"
				printf "%*s\n\n\n" $((COLS/2)) "$UIsep_title"
			}
		fi
		echo "Initializing.." &
	fi

	scriptDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

	# make logs directory, but do not overwrite if already present
	mkdir ~/logs/ >/dev/null 2>&1

	# mac osx only; set font size to 15p
	osascript -e "tell application \"Terminal\" to set the font size of window 1 to 15" > /dev/null 2>&1
	updateIP
}

clear; INIT # initializing now..
# nothing up until the first call of MAIN will be run; only being loaded into memory

# set debug variant of core commands
if [ "$verbose" = 1 ] || [ "$verbose" = 2 ]; then
	if [ "$verbose" = "2" ]; then set -x; fi
	CMD_communicate(){ printf "\n\nChecking device connection status..\n"; adb -d shell exit; }
	CMD_uninstall(){ echo "Uninstalling $OBBname.."; adb uninstall "$OBBname"; sleep 0.5; }
	CMD_launch(){ printf "\n\nRunning monkey event to launch app..\n\n"; adb -d shell "$launchCMD"; }

	CMD_pushOBB(){ adb push "$OBBfilePath" /sdcard/Android/OBB; }
	CMD_installAPK(){ (adb install -r --no-streaming "$APKfilePath" && exit) || (
		printf "\n--no-streaming option failed\n\nAttempting default install type..\n"
		adb install -r "$APKfilePath" && exit || exit 1
	) }

	CMD_gitGet(){ git clone https://github.com/LysergikProductions/Android-Installer.git && {
			printf "\nGIT CLONED\n\n"; echo "Storing config values into variables.."
		} || { git pull printf "\nGIT PULLED\n\n"; }
	}
	printIP(){
		printf "Device IP: $deviceIP\nDevice IP Location: $deviceLOC\n"
		printf "\nComputer IP: $usrIP\n\n"
	}

	refreshUI(){ COLS=$(tput cols); printIP; adb devices; printTitle; }
	headerIP(){
		printf "$scriptFileName | Build $build\n2020 (C) $author\n$UIsep_err0\n\n$adbVersion\n\nBash version $bashVersion\n\n"
		printIP
		printf "\n$UIsep_head\n\nDistributed with the $license license\n\n$UIsep_head"
	}

	header(){
		printf "$scriptFileName | Build $build\n2020 (C) $author\n$UIsep_err0\n\n$adbVersion\n\nBash version $bashVersion\n"
		printf "\n$UIsep_head\n\nDistributed with the $license license\n\n$UIsep_head"
	}

	CMD_rmALL(){
		printf "\n\nrm -rf /tmp/variables.before /tmp/variables.after ~/upt ; tput cnorm\n"
		rm -rf /tmp/variables.before /tmp/variables.after ~/upt /tmp/usrIPdata.xml /tmp/devIPdata.xml
		tput cnorm
	}

	lastCatch(){
		scriptEndDate=$(date)
		printf "\nFINAL: caught error in MAINd's error handling\nI make a logfile with ALL system variables called ~/logs/FULL_$scriptEndDate.txt\n\n"
		( set ) > ~/logs/"FULL_$scriptEndDate".txt 2>&1
	}
else # set default variant of core commands
	CMD_communicate(){ adb -d shell exit 2>/dev/null; }
	CMD_uninstall(){
		if [ "$qMode" = "false" ]; then
			echo "Uninstalling $OBBname.."
			wait | adb uninstall "$OBBname" >/dev/null 2>&1; sleep 0.5; echo "Done!"
		else
			wait | adb uninstall "$OBBname" >/dev/null 2>&1; sleep 0.5
		fi
	}
	CMD_launch(){ adb -d shell "$launchCMD" >/dev/null 2>&1; }

	CMD_pushOBB(){ adb push "$OBBfilePath" /sdcard/Android/OBB 2>/dev/null; }
	CMD_installAPK(){ (adb install -r --no-streaming "$APKfilePath" 2>/dev/null && exit) || (
		printf "\n--no-streaming option failed\n\nAttempting default install type..\n"
		adb install -r "$APKfilePath" 2>/dev/null && exit || exit 1
	) }

	CMD_gitGet(){ git clone https://github.com/LysergikProductions/Android-Installer.git >/dev/null 2>&1 || {
			git pull >/dev/null 2>&1
		}
	}
	printIP(){
		printf "Device IP: $deviceIP\nDevice IP Location: $deviceLOC"
	}

	if [ "$qMode" = "false" ]; then
		refreshUI(){ COLS=$(tput cols); printHead; adb devices; printTitle; }
	else
		refreshUI(){ COLS=$(tput cols); printHead; }
	fi

	headerIP(){
		printf "$scriptFileName | Build $build\n2020 (C) $author\n$UIsep_err0\n"
		printIP
		printf "\n$UIsep_head\n\nDistributed with the $license license\n\n$UIsep_head\n\n"
	}

	header(){
		printf "$scriptFileName | Build $build\n2020 (C) $author"
		printf "\n$UIsep_err0\n\nDistributed with the $license license\n\n$UIsep_head\n"
	}

	CMD_rmALL(){
		rm -rf /tmp/variables.before /tmp/variables.after ~/upt /tmp/usrIPdata.xml /tmp/devIPdata.xml
		tput cnorm
	}

	lastCatch(){
		scriptEndDate=$(date)
		( set ) > ~/logs/"FULL_$scriptEndDate".txt 2>&1
	}
fi

updateScript(){
	clear; printf "\n%*s\n\n" $((COLS/2)) "Updating Script:"

	if [ "$verbose" = 1 ]; then printf "\nCopying new version of script into current script directory\n"; sleep 0.6; fi
	cpSource=~/upt/Android-Installer/$scriptPrefix$currentVersion.sh

	trap "" SIGINT
	cp "$cpSource" "$scriptDIR" && upToDate="true"
	trap exitScript SIGINT SIGTERM

	echo "Launching updated version of the script!"; sleep 1
	exec "$scriptDIR/$scriptPrefix$currentVersion.sh" || { errExec="true" && gitConfigs; }
}

gitConfigs(){
	if [ "$verbose" = 1 ]; then printf "\nDownloading configs..\n\n"; fi
	terminalPath=""; terminalPath=$(pwd)
	rm -rf ~/upt; mkdir ~/upt; cd ~/upt || return

	# clone repo or update it with git pull if it exists already
	(CMD_gitGet); wait
	cd "$terminalPath" || return

	# get config values from the master branch's properties.txt
	currentVersionLine=$(grep -n "_version " ~/upt/$gitName/properties.txt)
	currentVersion="${currentVersionLine##* }"; currentVersion=${currentVersion%$'\r'}

	newVersionLine=$(grep -n "_newVersion " ~/upt/$gitName/properties.txt)
	newVersion="${newVersionLine##* }"; newVersion=${newVersion%$'\r'}

	gitMESSAGELine=$(grep -n "_gitMESSAGE " ~/upt/$gitName/properties.txt)
	gitMESSAGE="${gitMESSAGELine##* }"; gitMESSAGE=${gitMESSAGE%$'\r'}

	dispGitTimeLine=$(grep -n "_dispGitTime " ~/upt/$gitName/properties.txt)
	dispGitTime="${dispGitTimeLine##* }"; dispGitTime=${dispGitTime%$'\r'}

	# set scriptTitle to match config, else use default
	if scriptTitle=$(grep -n "_scriptTitle " ~/upt/Android-Installer/properties.txt); then
		scriptTitle="${scriptTitle##* }"
	else scriptTitle="$scriptTitleDEF"; fi

	if [ "$currentVersion" = "$scriptVersion" ]; then
		upToDate="true"
		printf "\n%*s\n" $((COLS/2)) "This script is up-to-date!"; sleep 1
	elif [ "$newVersion" = "$scriptVersion" ]; then
		upToDate="true"
		printf "\n%*s\n" $((COLS/2)) "This script is up-to-date!"; sleep 1
	else
		if [ "$errExec" = "false" ]; then
			upToDate="false"
			printf "\n\n\n\n\n%*s\n" $((COLS/2)) "This script: v$scriptVersion"
			printf "\n%*s\n" $((COLS/2)) "Latest version: v$currentVersion"
			printf "%*s\n" $((COLS/2)) "Version in progress: v$newVersion"

			printf "\n%*s" $((COLS/2)) "Update required..."; sleep 2
			if [ "sMode" = "false" ]; then updateScript; fi
		elif [ "$errExec" = "true" ]; then
			echo "error when launching new script.. ignoring"; sleep 1
		fi
	fi

	# display gitMESSAGE if there is one
	if [ "$dispGitTime" = "" ]; then dispGitTime=0; fi
	if [ ! "$gitMESSAGE" = "" ]; then clear; echo "$gitMESSAGE"; sleep "$dispGitTime"; fi
}

printHead(){
	if [ "$loopFromError" = "false" ]; then
		if [ "$verbose" = 0 ]; then clear; fi
		if [ "$showIP" = "true" ] && [ "$qMode" = "false" ]; then headerIP; else header; fi
	elif [ "$loopFromError" = "true" ]; then
		if [ "$verbose" = 0 ]; then clear; fi
		if [ "$showIP" = "true" ] && [ "$qMode" = "false" ]; then headerIP; else header; fi
		printf "$errorMessage\n\n"
  	else # if bug causes loopFromError to be NOT "true" or "false", then fix value and reset script
		export errorMessage="$errorMessage\n\n$UIsep_err0\n\n"
		export errorMessage+="ER1 - Script restarted; 'loopFromError' had an unexpected value."
		export loopFromError="true"

		printf "\nER1 - Unexpected value in 'loopFromError'; resetting script in..\n"
		printf "3.. "; sleep 1; printf "2.. "; sleep 1; printf "1.. "; sleep 1
		MAINd
  	fi
}

warnFIRE(){
	flashWarn=(
		"!Remember!" "" "!Remember!" "" "!Remember!"
	)
	tput civis
	for i in "${flashWarn[@]}"
	do
		printf "\r%*s" $((COLS/2)) "$i"
		sleep 0.3
	done
	printf "\r%*s\n\n" $((COLS/2)) "To test the store, use the download link method"
	tput cnorm
}

# default MAIN function that uninstalls first in case of existing version of the app on the device
MAINd(){
	deviceID=""; deviceID2=""

	printf '\e[8;50;150t'; printf '\e[3;290;50t'
	gitConfigs; COLS=$(tput cols)

	# try communicating with device, catch with adbWAIT, finally mount device
	(CMD_communicate 1>/dev/null) || adb start-server
	adb -d shell settings put global development_settings_enabled 1

	refreshUI
	tput cnorm # ensure cursor is visible and that crtl-C is functional

	getOBB; getAPK; INSTALL && echo || {
		printf "\nMAINd: caught fatal error in INSTALL\nSave varLog now\n"

		export scriptEndDate=""; scriptEndDate=$(date)
		export errorMessage="FE0 - Fatal Error. Copying all var data into ~/logs/$scriptEndDate.txt"
		printf "\nFE0 - Fatal Error.\nCopying all var data into ~/logs/$scriptEndDate.txt\n\n"

		diff /tmp/variables.before /tmp/variables.after > ~/logs/"$scriptEndDate".txt 2>&1
	} || (echo "catch fails"; exit 1)
}

# update MAIN function that does not delete app data, and only updates the build (beta feature)
MAINu(){
	deviceID=""; deviceID2=""; scriptTitle="  MONKEY UPDATER  "

	COLS=$(tput cols)
	printf '\e[8;50;150t'; printf '\e[3;290;50t'
	gitConfigs

	# try communicating with device, catch with adbWAIT, finally mount device
	(CMD_communicate && wait) || adb start-server
	adb -d shell settings put global development_settings_enabled 1

	refreshUI
	tput cnorm # ensure cursor is visible and that crtl-C is functional

	echo "OBB will not actually be replaced on your device, but it is still required.."
	getOBB; getAPK; UPSTALL && echo || {
		printf "\nMAINd: caught fatal error in INSTALL\nSave varLog now\n"

		export scriptEndDate=""; scriptEndDate=$(date)
		export errorMessage="FE0 - Fatal Error. Copying all var data into ~/logs/$scriptEndDate.txt"
		printf "\nFE0 - Fatal Error.\nCopying all var data into ~/logs/$scriptEndDate.txt\n\n"

		diff /tmp/variables.before /tmp/variables.after > ~/logs/"$scriptEndDate".txt 2>&1
	} || (echo "catch fails"; exit 1)
}

getOBB(){
	printf "\n%*s\n" $((COLS/2)) "$OBBquest"; printf "$OBBinfo"
	read -p '' OBBfilePath #i.e. Server:\folder\ folder/folder/com.studio.platform.appName
	OBBfilePath="${OBBfilePath%* }"

	local cleanPath="${OBBfilePath#*:*}"; OBBname=$(basename "$cleanPath")

	if [ "$OBBfilePath" = "" ]; then
		refreshUI
		printf "%*s\n" $((COLS/2)) "$oops"; sleep 0.05
		printf "%*s\n\n" $((COLS/2)) "You forgot to drag the OBB!"
		getOBB
	elif [ "$OBBfilePath" = "fire" ]; then
		OBBvalid="true"; OBBdone="true"
		UNINSTALL="false"; LAUNCH="false"

		refreshUI; warnFIRE

		printf "Which Amazon app would you like to install?\n"
		select opt in "${fireAPPS[@]}"
		do
			case $opt in
			"GO BACK")
					refreshUI; getOBB
				break
					;;
			*)
				UNINSTALL="true"; LAUNCH="true"; OBBname="com.$studio.amazon.$opt"
				launchCMD="monkey -p $OBBname -c android.intent.category.LAUNCHER 1"

				printf "OBB Name: $OBBname\n\n"
				break
					;;
			esac
	      done
	elif [ "$OBBfilePath" = "na" ] || [ "$OBBfilePath" = "0" ] || [ "$OBBfilePath" = "." ]; then
		OBBvalid="true"; OBBdone="true"; LAUNCH="false"
		printf "OBB Name: N/A"
	elif [[ "$OBBname" == "com."* ]]; then
		OBBvalid="true"; LAUNCH="true"
		printf "OBB Name: $OBBname\n\n"
		launchCMD="monkey -p $OBBname -c android.intent.category.LAUNCHER 1"
	else
		OBBvalid="false"
	fi

	until [ "$OBBvalid" = "true" ]; do
		refreshUI
		printf "%*s\n" $((COLS/2)) "$oops"; sleep 0.05
		printf "\n%*s\n\n" $((COLS/2)) "That is not an OBB!"
		printf "I'm sorry, I don't know what to do with this file..\n\n$OBBname\n"

		getOBB
	done
}

getAPK(){
	APKvalid="true"
	printf "\n%*s\n\n" $((COLS/2)) "$APKquest"
	read -p '' APKfilePath
	APKfilePath="${APKfilePath%* }"

	local cleanPath="${APKfilePath#*:*}"; APKname=$(basename "$cleanPath")

	if [ "$APKfilePath" = "" ]; then
		refreshUI
		APKvalid="false"
		printf "%*s\n" $((COLS/2)) "$oops"; sleep 0.05
		printf "%*s\n\n" $((COLS/2)) "You forgot to drag the APK!"
		getAPK
	elif [[ "$APKname" == *".apk" ]]; then
		APKvalid="true"
		printf "APK Name: $APKname\n\n"
	else
		APKvalid="false"
	fi

	until [ "$APKvalid" = "true" ]; do
		refreshUI
		printf "%*s\n" $((COLS/2)) "$oops"; sleep 0.05
		printf "%*s\n\n" $((COLS/2)) "That is not an APK!"
		printf "I'm sorry, I don't know what to do with this file..\n\n$APKname\n"
		getAPK
	done
	echo
}

INSTALL(){
	tput civis
	scriptTitle="Installing.."; showIP="true"

	printHead; adbWAIT

	if [  "$qMode" = "false" ]; then
		printf "Mounting device...\n"
		adb devices
	else
		echo
	fi

	# uninstall app, unless APK step wants to continue from where it left off
	if [ "$UNINSTALL" = "true" ]; then
		wait | CMD_uninstall
		UNINSTALL="true"
	fi

	printTitle

	# upload OBB, only if it isn't already uploaded on deviceID
	if [ "$OBBdone" = "false" ] && [[ "$OBBname" == "com."* ]]; then
		printf "\nUploading OBB..\n"
		if (CMD_pushOBB && exit) || (
				(CMD_communicate && deviceConnect="true") || deviceConnect="false"
				if [ "$deviceConnect" = "true" ]; then
					errorMessage="FE1a - OBB could not be installed."
					printf "\n\nFE1a - OBB could not be installed.\n"

					( set -o posix ; set ) >/tmp/variables.after
					echo "Please report this error code (FE1a) to Nick."; exit 1
				else OBBdone="false"; INSTALL; fi
			); then
				OBBdone="true"
				adbWAIT; deviceConnect="true"; deviceID=$(adb devices)
		else (exit 1); fi
	fi

	adbWAIT

	# install APK, only if APKdone=false
	if [ "$APKdone" = "false" ] && [[ "$APKname" == *".apk"* ]]; then
		if [[ "$OBBfilePath" == *"fire"* ]]; then
			printf "\n%*s\n\n" $((COLS/2)) "It may take a long time to install builds on this device.."
		fi

		printf "\nInstalling APK..\n"
		if CMD_installAPK || (
			(CMD_communicate && deviceConnect="true") || deviceConnect="false"
			if [ "$deviceConnect" = "true" ]; then
				errorMessage="FE1b - APK could not be installed."
				printf "\n\nFE1b - APK could not be installed.\n"

				( set -o posix ; set ) >/tmp/variables.after
				echo "Please report this error code (FE1b) to Nick."; exit 1
			else APKdone="false"; UNINSTALL="false"; INSTALL; fi
		); then
			APKdone="true"
			adbWAIT; deviceConnect="true"; deviceID=$(adb devices)

			if [ "$LAUNCH" = "true" ]; then
				CMD_launch &
				printf "\n\nLaunching app."; sleep 0.4; printf " ."; sleep 0.4; printf " ."; sleep 0.4; printf " .\n"
				tput cnorm; installAgainPrompt
			else
				tput cnorm; installAgainPrompt
			fi
		else (exit 1); fi
	fi
	tput cnorm
}

UPSTALL(){
	scriptTitle=" INSTALLING.. "; showIP="true"

	printHead; adbWAIT; UNINSTALL="false"
	printf "\nMounting device...\n"
	adb devices

	# uninstall app, unless APK step wants to continue from where it left off
	if [ "$UNINSTALL" = "true" ]; then
		wait | CMD_uninstall
		UNINSTALL="true"
	fi

	deviceID=$(adb devices); echo; printTitle

	# install APK, only if APKdone=false
	if [ "$APKdone" = "false" ] && [[ "$APKname" == *".apk"* ]]; then
		printf "\nInstalling APK..\n"

		if CMD_installAPK || (
			(CMD_communicate && deviceConnect="true") || deviceConnect="false"
			if [ "$deviceConnect" = "true" ]; then
				errorMessage="FE1b - APK could not be installed."
				printf "\n\nFE1b - APK could not be installed.\n"

				( set -o posix ; set ) >/tmp/variables.after
				echo "Please report this error code (FE1b) to Nick."; exit 1
			else APKdone="false"; UNINSTALL="false"; INSTALL; fi
		); then
			printf "\ncheck for proper connect, and define deviceID(1)\nLaunch App\n"
			APKdone="true"
			adbWAIT; deviceConnect="true"; deviceID=$(adb devices)

			if [ "$LAUNCH" = "true" ]; then
				CMD_launch
				printf "\n\nLaunching app."; sleep 0.4; printf " ."; sleep 0.4; printf " ."; sleep 0.4; printf " .\n"
				tput cnorm; installAgainPrompt
			else
				tput cnorm; installAgainPrompt
			fi
		else (exit 1); fi
	fi
}

# check if user wants to install again on another device, or the same device if they choose to
installAgainPrompt(){
	scriptTitle="Install Again?"; showIP="true"
	updateIP

	refreshUI
	printf "\n%*s\n" $((COLS/2)) "Press 'q' to quit"
	printf "\n%*s\n" $((COLS/2)) "Press 't' to see device CPU and RAM stats"
	printf "\n%*s\n" $((COLS/2)) "Press 'r' to install different build"
	printf "\n\n%*s\n" $((0)) "!Press any other key to install this build again!"
	printf "\n%*s\n" $((0)) "$APKname"
	read -n 1 -s -r -p ''
	if [ "$REPLY" = "q" ]; then
		OBBdone="true"; APKdone="true"; LAUNCH="false"
		(exit)
	elif [ "$REPLY" = "r" ]; then
		OBBdone="false"; APKdone="false"; UNINSTALL="true"

		refreshUI; tput cnorm

		getOBB; getAPK; INSTALL && echo || {
			printf "\nMAINd: caught fatal error in INSTALL\nSave varLog now\n"

			export scriptEndDate=""; scriptEndDate=$(date)
			export errorMessage="FE0 - Fatal Error. Copying all var data into ~/logs/$scriptEndDate.txt"
			printf "\nFE0 - Fatal Error.\nCopying all var data into ~/logs/$scriptEndDate.txt\n\n"

			diff /tmp/variables.before /tmp/variables.after > ~/logs/"$scriptEndDate".txt 2>&1
		} || (echo "catch fails"; exit 1)
	elif [ "$REPLY" = "t" ]; then
		clear
		if adb -d shell exit; then
			updateIP
			{ sleep 0.5; while (trap exitScript SIGINT SIGTERM)
				do
					printf "\n%*s\n" $((COLS/2)) "Device IP Location: $deviceLOC"
					sleep 1.99
				done
			} & adb -d shell top -d 2 -m 5 -o %MEM -o %CPU -o CMDLINE -s 1 || exit
		else exit 1; fi
	else
		OBBdone="false"; APKdone="false"
		installAgain
	fi
}

installAgain(){
	adbWAIT
	deviceID2=$(adb devices); wait

	if [ "$deviceID" = "$deviceID2" ]; then
		refreshUI
		printf "\n\n%*s\n" $((COLS/2)) "This is the same device! Are you sure you want to install the build on this device again?"
		printf "\n%*s\n" $((COLS/2)) "Press 'y' to install on the same device, or any other key when you have plugged in another device."

		read -n 1 -s -r -p ''
		if [ "$REPLY" = "y" ]; then
			UNINSTALL="true"; INSTALL
		else
			adbWAIT; deviceID2=$(adb devices); wait; installAgainPrompt; exit 1
		fi
	else
		INSTALL
	fi
	tput cnorm
}

# update the script on status of adb connection and call waiting function until it is ready
adbWAIT(){
	if (CMD_communicate); then
		export deviceConnect="true"
	else
		tput civis
		printf "\n\n%*s\n" $((COLS/2)) "$waitMessage"
		{ sleep 3; printf "        Ensure only one device is connected!"; } & { 
			until (CMD_communicate)
			do
				if [ "$sMode" = "false" ]; then waiting; fi; deviceConnect="true"
			done
		}
		tput cnorm
		printf "\r%*s\n\n" $((COLS/2)) "!Device Connected!   "
	fi
}

# show the waiting animation
waiting(){
	tput civis
	for i in "${anim1[@]}"
	do
		printf "\r%*s" $((COLS/2)) "$i"
		sleep 0.045
	done
}

readQ(){
	while read -rsn1 ui; do
		case "$ui" in
		$'\x1b')    # Handle ESC sequence.
			# Flush read. We account for sequences for Fx keys as
			# well. 6 should suffice far more then enough.
			read -rsn1 -t 0.1 tmp
			if [[ "$tmp" == "[" ]]; then
				read -rsn1 -t 0.1 tmp
				case "$tmp" in
				"A") printf "Up\n";;
				"B") printf "Down\n";;
				"C") printf "Right\n";;
				"D") printf "Left\n";;
				esac
			fi
			# Flush "stdin" with 0.1  sec timeout.
			read -rsn5 -t 0.1
			;;
		# Other one byte (char) cases. Here only quit.
		q) break;;
		esac
	done
}

if [[ "$*" == "--update" ]] || [[ "$*" == *"-u"* ]]; then
	# try update, catch
	readQ & MAINu && echo || lastCatch
else
	# try install, catch
	readQ & MAINd && echo || lastCatch
fi

# finally remove temporary data created by the script and exit
CMD_rmALL
printf "\nGoodbye!\n"; exit
