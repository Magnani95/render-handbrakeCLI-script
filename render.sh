#!/bin/bash

# TODO
# - Queue for list of input-renders and for finished one.
# - All file in a directory

#BUG TO FIX
# - QUIET need to be VERBOSE
# - FORCE_MODE should be FORCE+INPUT_ACCEPT+WRITE mode [-F -I -W]

##FUN DEFINITION
echo "Function definition..."
function argument_parsing_F()
{
	for p in $@; do
		if [[ $p =~ -F|--force ]]; then
			FORCE_MODE='TRUE'
		fi
	done

	while [[ $# -gt 0 ]]; do
		param="$1"
		#INPUT FILE
		if [[ "$1" =~ .*\.mp4|.*\.mkv|.*\.avi ]]; then
			echo "'$1' is detected to be the input file"
			if [[ $FORCE_MODE == 'FALSE' ]]; then
				while [[ ! $REPLY =~ ^[ynYN] ]]; do
					read -p "Is that correct?[y|n]" -r -n 1 && echo
				done
			else
				echo "Force-mode accepted input file"
				REPLY='y'
			fi
			case $REPLY in
				y|Y)
				INPUT_PARAM="$1"
				shift;
				continue;
				;;
				n|N)
				echo "Exit"
				exit 0
				;;
				*)
				echo 'DEF: argument_parsing_F case $REPLY'
				exit 255
				;;
			esac
			REPLY=''
		fi

		case $param in
			#PARAM WITH VAL
			-q | --quality )
			QUALITY="$2"
			shift; shift;
			;;
			-p | --preset)
			PRESET="$2"
			shift; shift;
			;;
			-s | --subtitle)
			SUB_STRING="$SUBSTRING""$2"
			shift; shift;
			;;
			#SINGLE PARAM
			-f | --find-sub)
			FIND_SUB='TRUE'
			shift;
			;;
			-v | --verbose)
			QUIET=''
			shift;
			;;
			-F | --force)
			FORCE_MODE='TRUE'
			shift;
			;;
			#--Queue Management
			-Q | --queue)
			if [[ -e "${CONFIG_DIR}/queue" ]]; then
				echo "Queue file exist" && echo "---"
				cat "${CONFIG_DIR}/queue"
				exit 1
			else
				touch "${CONFIG_DIR}/queue"
				echo "Queue file does not exist. It has been created."
				exit 1
			fi
			shift;
			;;
			-QA | --queue-add)
			QUEUE_MODE='ADD'
			shift;
			;;
			-QX | --queue-execution)
			QUEUE_MODE='RUN'
			shift;
			;;
			#OTHER
			*)
			echo "Param. '$1'" && echo "Exit the program (specify '-F|--force' otherwise)"
			echo "Not implemented yet :)"
			exit 3
			;;
		esac
	done
	if [[ -z ${INPUT_PARAM} && ${FORCE_MODE} =~ 'FALSE' && ! ${QUEUE_MODE} =~ RUN ]]; then
		echo "Error, no Input file detected in parameters"
		exit 2
	fi
}

function confirm_F()
{
	if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]];then
		echo "[SSH] Output file exists and cannot be overwritten"
		echo "[SSH] remove it and retry"
		exit 1
	fi
	REPLY=''
	while [[ ! $REPLY =~ ^[yn] ]]; do
		echo "File: $OUTPUT_FILE"
		read -p "Output file exists. Overwrite it?[y|n]" -r -n 1 && echo
	done
	if [[ $REPLY = 'y' ]]; then
		echo "Ovewriting..."
	else
		echo "Exit the program"
		exit 1
	fi
	REPLY=''
}
function gatherSub_F()
{
	:
}

function getSub_F()
{
	#echo "find $DIRPATH -regex '.*\.srt'"
	#echo $DIRPATH
	echo "$SUB_STRING"
	REPLY=''
	if [[ $FIND_SUB =~ 'TRUE' ]]; then
		readarray  SUBFILES < <(find "$DIRPATH" -type f -regex '.*\.srt' -print)

		for s in "${SUBFILES[@]}"; do
			s=`echo "$s" | xargs `
			while [[ ! $REPLY =~ ^[ynax] ]]; do
				echo "File: $s"
				read -p "Add the subtitles file?[y|n|a|x]" -r -n 1 && echo
			done

			if [[ $REPLY = 'y' ]]; then
				echo "File added"
				if [[ -z $SUB_STRING ]]; then
					SUB_STRING="${s}"
				else
					SUB_STRING="${SUB_STRING},${s}"
				fi
				REPLY=''
			elif [[ $REPLY = 'n' ]]; then
				echo "File ignored"
				REPLY=''
			elif [[ $REPLY = 'a' ]]; then
				echo "Sequential adding:		$s"
				if [[ -z $SUB_STRING ]]; then
					SUB_STRING="${s}"
				else
					SUB_STRING="${SUB_STRING},${s}"
				fi
			elif [[ $REPLY = 'x' ]]; then
				echo "Sequential ignoring:		$s"
			else
				echo "DEF IMPOSSIBLE branch in getSub_F"
				exit 255
			fi
		done
		if [[ $QUIET =~ 'FALSE' ]]; then
			echo "++FINAL SUB STRING"
			echo $SUB_STRING
		fi
	fi
	REPLY=''

}

function command_creation_F()
{
	FILEPATH=`realpath "$INPUT_PARAM"`

	DIRPATH=`dirname "$FILEPATH"`
	FILENAME=`echo "$FILEPATH"|sed 's|.*/\(.*\)\..*|\1|'`
	echo "dir: "$DIRPATH""
	echo "file: "$FILEPATH""

	#--INPUT
	INPUT_FILE="$FILEPATH"
	#--OUTPUT FILE
	OUTPUT_FILE="${OUTPUT_DIR}${FILENAME}.mkv"
	if [[ -e $OUTPUT_FILE ]]; then
		confirm_F
	fi
	#ENCODER SETTINGS
	VIDEO="-e x265 -q $QUALITY --encoder-preset $PRESET"
	AUDIO="--all-audio -E av_aac -6 dpl2 --all-subtitles "
	FILTERS=''
	EXTRA="-x pmode:pools='16'" #"wpp:pools='thread count'"		#var=val:var=val
	#--SUB
	getSub_F
	if [[ -n $SUB_STRING ]]; then
		SUB="--srt-file \""$SUB_STRING"\" "
	fi
	#--LANCIO RENDER
	COMMAND="HandBrakeCLI -i \""${INPUT_FILE}"\" -o \""${OUTPUT_FILE}"\" $VIDEO $AUDIO $FILTERS $EXTRA "${SUB}" $QUIET"

}

##-----------------------
##----------MAIN-------------
echo "Variable definition..."
#--DEFAULT
INPUT_PARAM=''
QUALITY="23"
PRESET="slow"
REPLY=''
#--Mode
FIND_SUB='FALSE'
FORCE_MODE='FALSE'
QUIET="--verbose=0 2> /dev/null"
QUEUE_MODE='FALSE'
#--Directory
OUTPUT_DIR="/hdd/Render/Output/"
CONFIG_DIR='/hdd/Render/'
#--
argument_parsing_F "$@"

if [[ ${QUEUE_MODE} = 'FALSE' ]]; then
	command_creation_F "$@"
	echo "++" && echo "$line" && echo "++"
	eval "$COMMAND"
	exit 0
elif [[ ${QUEUE_MODE} = 'ADD' ]]; then
	command_creation_F "$@"
	echo "++" && echo "$line" && echo "++"
	echo "$COMMAND" >> "${CONFIG_DIR}/queue"
	echo "Job added to the queue"
	exit 0
elif [[ ${QUEUE_MODE} = 'RUN' ]]; then
	QUEUE_LEN=`cat ${CONFIG_DIR}/queue | wc -l`
	QUEUE_POS='1'
	printf "Queue lenght:\t ${QUEUE_LEN}\n"
	#RENDER=`head -n 1 ${CONFIG_DIR}/queue`
	while IFS= read -r line; do
		echo "--Running render ${QUEUE_POS} on ${QUEUE_LEN}..."
		echo "++" && echo "$line" && echo "++"
		eval "${line}"
		tail -n +2 "${CONFIG_DIR}/queue" > "${CONFIG_DIR}/queue.tmp" && mv "${CONFIG_DIR}/queue.tmp" "${CONFIG_DIR}/queue"
		echo "--Render ended" && QUEUE_POS=`expr $QUEUE_POS + 1`
	done < "${CONFIG_DIR}/queue"

	exit 0
else
	echo "DEF IMPOSSIBLE if-else in main-end "
	exit 255
fi
echo "DEF IMPOSSIBLE in main-end "
exit 255
