#!/bin/bash

success="false"

# install platform-tools
brew cask install android-platform-tools && success="true" || {
	set -x
	# error, so install Homebrew and try again
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	brew cask install android-platform-tools && success="true"
}

xcode-select --install >/dev/null

if [ "$success" = "true" ]; then
	printf "\nSuccess!\n\n Type 'adb devices' after connecting an Android device.\nThen accept the USB debugging prompt on the device to get started!\n"
else
	printf "\nFailure!\n\n"
fi