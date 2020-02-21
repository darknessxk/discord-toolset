#!/bin/bash

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'

echo -e "${NC}"
echo [Discord Toolset] Customizing your Discord was never that easy
echo -e "This tool was originally created by ${RED}darknessxk${NC}"

if [ ! -d "/home/$USER/.config/discord" ]; then
	echo "Install discord first"
	exit;
fi

if [ ! -d "/usr/share/discord" ]; then
	echo "Install discord first"
	exit;
fi

asar=$(npm bin)/asar

if [ ! -f $asar ]; then
	asar=$(npm bin -g)/asar

	if [ ! -f $asar ]; then
		echo -e "Asar not found, please install asar using ${GREEN}npm i -g asar${NC}"
		exit 127
	fi
	fi

	DISCORD_MAIN=/usr/share/discord
	DISCORD_PATH=/home/$USER/.config/discord

	SETTINGS_PATH=$DISCORD_PATH/settings.json
	MODULES_PATH=$(find $DISCORD_PATH -type d -name "modules")

# ASAR FILES
DESKTOP_CORE=$MODULES_PATH/discord_desktop_core/core.asar
DISCORD_APP=$DISCORD_MAIN/resources/app.asar

DISCORD_VERSION="$(echo $DESKTOP_CORE | grep -ohE [0-9].[0-9].[0-9])"

OUTPUT_FOLDER="$(pwd)/output"

if [ ! -d $OUTPUT_FOLDER ]; then
	mkdir -p $OUTPUT_FOLDER
fi

MAIN_OUTPUT=$OUTPUT_FOLDER/main

if [ ! -d $MAIN_OUTPUT ]; then
	mkdir -p $OUTPUT_FOLDER
fi

RENDERER_OUTPUT=$OUTPUT_FOLDER/renderer

if [ ! -d $RENDERER_OUTPUT ]; then
	mkdir -p $OUTPUT_FOLDER
fi

MODE=0
INSTANCE=0

#################################################################################################################
# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

# -allow a command to fail with !’s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
	echo 'I’m sorry, `getopt --test` failed in this environment.'
	exit 1
fi

OPTIONS=m:i:o:
LONGOPTS=instance:,mode:,output:

# -regarding ! and PIPESTATUS see above
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
	# e.g. return value is 1
	#  then getopt has complained about wrong arguments to stdout
	exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

while true; do
	case "$1" in
		-m|--mode)
			MODE=$2
			shift 2
			;;
		-i|--instance)
			case $2 in
				renderer)
					INSTANCE="renderer";;
				main)
					INSTANCE="main";;
				*)
					echo "Invalid instance type"
					exit;;
			esac
			shift 2
			;;
		--)
			shift
			break
			;;
		*)
			echo "Programming error ($1)"
			exit 3
			;;
	esac
done

##############################################################################################################################

LAST_ERROR_CODE=$?

echo -e "Discord found at ${GREEN}$DISCORD_PATH${NC}"

function help {
	echo -e "${RED}Mode needs to be set${NC}"
	echo "* = Requires Sudo"
	echo "$0 --mode=... --instance=..."
	echo -e "Usage $0 --mode=${GREEN}(extract | build | version | path | backup | symlink*)${NC} --instance=${RED}(main/m* | renderer/r | all)${NC}"
	exit;
}

function build_error_check_fn {
	if [ $LAST_ERROR_CODE -gt 0 ]; then
		echo -e "${RED}Build failed with error code $LAST_ERROR_CODE ${NC}"
	else
		echo -e "${GREEN}Build completed${NC}"
	fi
}

function extraction_error_check_fn {
	if [ $LAST_ERROR_CODE -gt 0 ]; then
		echo -e "${RED}Failed to extract with error code $LAST_ERROR_CODE ${NC}"
	else
		echo -e "${GREEN}Extraction completed${NC}"
	fi

}

function build_renderer_fn {
	echo Building renderer

	$asar p $RENDERER_OUTPUT $DESKTOP_CORE
	LAST_ERROR_CODE=$?

	build_error_check_fn
}

function build_main_fn {
	echo Building Main and sending directly to $DISCORD_APP

	$asar p $MAIN_OUTPUT $DISCORD_APP
	LAST_ERROR_CODE=$?

	build_error_check_fn
}

function build_fn {
	case $INSTANCE in
		main)
			echo Building only Main
			build_main_fn;;
		renderer)
			echo Building only Renderer
			build_renderer_fn;;
		*)
			echo Building everything
			build_main_fn
			build_renderer_fn;;
	esac

	exit
}


function extract_renderer_fn {
	echo "Extracting Desktop Core file to $RENDERER_OUTPUT"

	$asar e $DESKTOP_CORE $RENDERER_OUTPUT
	LAST_ERROR_CODE=$?

	extraction_error_check_fn
}

function extract_main_fn {
	echo "Extracting Main App file to $MAIN_OUTPUT"

	$asar e $DISCORD_APP $MAIN_OUTPUT
	LAST_ERROR_CODE=$?

	extraction_error_check_fn
}


function extract_fn {
	case $INSTANCE in
		main|Main|m)
			echo Extracting only Main
			extract_main_fn;;
		renderer|Renderer|r)
			echo Extracting only Renderer
			extract_renderer_fn;;
		*)
			echo Extracting everything
			extract_main_fn
			extract_renderer_fn;;
	esac
	exit
}

case $MODE in
	build)
		echo "Build mode is set"
		build_fn;;
	extract)
		echo "Extract mode is set"
		extract_fn;;
	version)
		echo -e "Discord version ${GREEN}$DISCORD_VERSION${NC}";;
	path)
		echo -e "Discord renderer path: ${GREEN}$DISCORD_PATH${NC} | main path: ${GREEN}$DISCORD_MAIN${NC}";;
	backup)
		echo "Function pending heh";;
	symlink)
		echo "Function pending heh";;
	*)
		help;;
esac
