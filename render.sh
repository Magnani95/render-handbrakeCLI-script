#!/bin/bash

# TODO
# - FORCE_MODE should be FORCE+INPUT_ACCEPT+WRITE mode [-F -I -W]
# - sub search in subdir of file OR in cwd as distinct option
# - Queue for list of input-renders and for finished one.
# - All file in a directory

#BUG TO FIX

##FUN DEFINITION
echo "Function definition..."
#--- Print Help
# - INPUT:	<None>
# - SET:	INPUT_FILES
# - MODIFY:	<None>
function help_F()
{
	echo "[This] is a program to manage HandbrakeCLI easily."
	echo "User will eventually asked about input if:"
	echo "	- more than one input-file is passed;"
	echo "	- Output file already exists;"
	echo "	- with --find-sub: which subfile add."
	echo
	echo "	NORMAL FLAGS"
	echo "-q|--quality [int] 				Set the quality"
	echo "-p|--preset [medium|slow|slower]		Set the preset"
	echo "-s|--subtitle	[file]				Add file to subtitles"
	echo "-f|--find-sub					Search sub in dir and subdir of input file"
	echo "-v|--verbose					Output is much more talkative"
	echo "	MODAL FLAGS"
	echo "-F|--force					Activate FORCE_MODE"
	echo "-FI|--force-input				First input-file is selected"
	echo "-FO|--force-output				Overwrite output-file without prompt"
	echo "	QUEUE MANAGEMENT"
	echo "-Q|--queue					Create the queue file or print it"
	echo "-QA|--queue-add					Add current COMMAND to queue"
	echo "-QX|--queue-exec				Run sequentialy COMMANDs in queue(Implict --force-output)(Current COMMAND is not added)"
	echo
	echo "FORCE_MODE: no input from user will be asked."
	echo "	- with --find-sub: all files found added"
}
#--- Pars the argument and set internal status accordingly
# - INPUT:	"$@" to pars arguments pass to the script
# - SET:	<None>
# - MODIFY:	<None>
function argument_parsing_F()
{
	for p in $@; do
			if [[ $p =~ -h|--help ]]; then
				help_F;
				exit 100
			fi
		done

	while [[ $# -gt 0 ]]; do
		if [[ "$1" =~ .*\.mp4|.*\.mkv|.*\.avi ]]; then
			echo "'$1' is detected to be a input file "
			INPUT_FILES+=("$1")
			shift;
			continue;
		fi
		param=$1
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
			SUB_STRING="$SUB_STRING""$2"
			shift; shift;
			;;
			# MODE FLAG
			-f | --find-sub)
			FIND_SUB='TRUE'
			shift;
			;;
			-v | --verbose)
			QUIET_MODE=''
			shift;
			;;
			-F | --force)
			FORCE_MODE='TRUE'
			shift;
			;;
			-FI | --force-input)
			FORCE_MODE_INPUT='TRUE'
			shift;
			;;
			-FO | --force-output)
			FORCE_MODE_OUTPUT='TRUE'
			shift;
			;;
			#--Queue Management
			-Q | --queue)
			if [[ -e "${CONFIGDIR}/queue" ]]; then
				echo "Queue file exist" && echo "---"
				cat "${CONFIGDIR}/queue"
				exit 1
			else
				touch "${CONFIGDIR}/queue"
				echo "Queue file does not exist. It has been created."
				exit 1
			fi
			shift;
			;;
			-QA | --queue-add)
			QUEUETMODE='ADD'
			shift;
			;;
			-QX | --queue-exec)
			QUEUETMODE='RUN'
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
	if [[ -z ${INPUT_FILES} && ${FORCE_MODE} =~ 'FALSE' && ! ${QUEUETMODE} =~ RUN ]]; then
		echo "Error, no Input file detected in parameters"
		exit 2
	fi
}
#--- Parse detected input files and prompt which one is to render.
# - INPUT:	[ext] INPUT_FILES, FORCE_MODE
# - SET:	INPUT_NAME
# - MODIFY:	<None>
function get_input_file_F()
{
	for (( i=0; i < ${#INPUT_FILES[@]}; i++ )) do
		REPLY=''

		if [[ -z ${INPUT_NAME} ]]; then	#first assignment
			INPUT_NAME=${INPUT_FILES[${i}]}
			if [[ $FORCE_MODE == 'TRUE' ]]; then
				echo "FORCE_MODE: the first file detected is set as input"
				break;
			else
				echo "+'${INPUT_FILES[${i}]}' is the file to render?"
				while [[ ! $REPLY =~ ^[ynYN] ]]; do
					read -p "Is that correct?[y|n]" -r -n 1 && echo
				done
				case $REPLY in
					y|Y)
					INPUT_NAME=${INPUT_FILES[${i}]}
					;;
					n|N)
					INPUT_NAME=''
					;;
					*)
					echo 'DEF: argument_parsing_F case $REPLY'
					exit 255
					;;
				esac
				REPLY=''
			fi
		else	#NOT first assignment
			echo "More than one input file"
			echo "+Actual selection is: ${INPUT_NAME}"
			echo "+Other file is: ${INPUT_FILES[${i}]}"
			while [[ ! $REPLY =~ ^[ynYN] ]]; do
				read -p "Do you want to change actual file? [y|n]?" -r -n 1 && echo
			done
			case $REPLY in
				y|Y)
				INPUT_NAME=${INPUT_FILES[${i}]}
				;;
				n|N)
				:
				;;
				*)
				echo 'DEF: argument_parsing_F case $REPLY'
				exit 255
				;;
			esac
			REPLY=''
		fi
	done
	if [[ -z $INPUT_NAME ]]; then
		echo "ERROR: No input file detected" && echo
		exit 1
	fi
	REPLY=''
}
#--- Check the existence of a output file which the same name and eventually
#	 prompt about overwrite
# - INPUT:	[ext] OUTPUT_FILES
# - SET:	<None>
# - MODIFY:	<None>
function confirm_F()
{
	if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]];then
		echo "[SSH] Output file exists and cannot be overwritten"
		echo "[SSH] remove it and retry"
		exit 1
	fi
	REPLY=''
	while [[ ! $REPLY =~ ^[yn] ]]; do
		echo "File: $OUTPUT_FILES"
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

#--- TODO search in probable position if there is any subfile
# - INPUT:	<None>
# - SET:	<None>
# - MODIFY:	<None>
function gatherSub_F()
{
	:
}

#--- Parse and search for .sub files position.
# - INPUT:	[ext] FIND_SUB, SUB_FILES, FIND_SUB, DIR_PATH
# - SET:	SUB_STRING
# - MODIFY:	SUB_FILES
function getSub_F()
{
	#echo "find $DIR_PATH -regex '.*\.srt'"
	#echo $DIR_PATH
	echo "$SUB_STRING"
	REPLY=''
	if [[ $FIND_SUB =~ 'TRUE' ]]; then
		readarray  SUB_FILES < <(find "$DIR_PATH" -type f -regex '.*\.srt' -print)

		for s in "${SUB_FILES[@]}"; do
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
		if [[ $QUIET_MODE =~ 'FALSE' ]]; then
			echo "++FINAL Sub STRING"
			echo $SUB_STRING
		fi
	fi
	REPLY=''

}
#--- Create COMMAND string to run to make render happens. It calls all the 
#	 functions required to create the command
# - INPUT:	<None>
# - SET:	COMMAND
# - MODIFY:	<None>
function COMMAND_creation_F()
{
	get_input_file_F
	FILEPATH=`realpath "$INPUT_NAME"`

	DIR_PATH=`dirname "$FILEPATH"`
	FILENAME=`echo "$FILEPATH"|sed 's|.*/\(.*\)\..*|\1|'`
	echo "+dir: "$DIR_PATH""
	echo "+file: "$FILEPATH""

	#--INPUT
	INPUT_FILE="$FILEPATH"
	if [[ ! -e $INPUT_FILE ]]; then
		echo "ERROR: the input file does not exists"
		exit 1
	fi
	#--OUTPUT FILE
	OUTPUT_FILES="${OUTPUT_DIR}${FILENAME}.mkv"
	if [[ -e $OUTPUT_FILES ]]; then
		confirm_F
	fi
	#ENCODER SETTINGS
	VIDEO="-e x265 -q $QUALITY --encoder-preset $PRESET"
	AUDIO="--all-audio -E av_aac -6 dpl2 --all-subtitles "
	FILTERS=''
	EXTRA="-x pmode:pools='16'" #"wpp:pools='thread count'"		#var=val:var=val
	#--Sub
	getSub_F
	if [[ -n $SUB_STRING ]]; then
		SUB="--srt-file \""$SUB_STRING"\" "
	fi
	#--LANCIO RENDER
	COMMAND="HandBrakeCLI -i \""${INPUT_FILE}"\" -o \""${OUTPUT_FILES}"\" $VIDEO $AUDIO $FILTERS $EXTRA "${SUB}" $QUIET_MODE"

}

##-----------------------
##----------MAIN-------------
echo "Variable definition..."
#--DEFAULT
INPUT_NAME=''
QUALITY="23"
PRESET="slow"
#INPUT_FILES=''
REPLY=''
#--Mode
FIND_SUB='FALSE'
FORCE_MODE='FALSE'
FORCE_MODE_INPUT='FALSE'
FORCE_MODE_OUTPUT='FALSE'
QUIET_MODE="--verbose=0 2> /dev/null"
QUEUETMODE='FALSE'
#--Directory
OUTPUT_DIR="./"		#"/hdd/Render/Output/"
CONFIGDIR="./"		#'/hdd/Render/'
#--
argument_parsing_F "$@"

if [[ ${QUEUETMODE} = 'FALSE' ]]; then
	COMMAND_creation_F "$@"
	echo "++" && echo "$COMMAND" && echo "++"
	eval "$COMMAND"
	exit 0
elif [[ ${QUEUETMODE} = 'ADD' ]]; then
	COMMAND_creation_F "$@"
	echo "++" && echo "$COMMAND" && echo "++"
	echo "$COMMAND" >> "${CONFIGDIR}/queue"
	echo "Job added to the queue"
	exit 0
elif [[ ${QUEUETMODE} = 'RUN' ]]; then
	queue_len=`cat ${CONFIGDIR}/queue | wc -l`
	queue_pos='1'
	printf "Queue lenght:\t ${queue_len}\n"
	#RENDER=`head -n 1 ${CONFIGDIR}/queue`
	while IFS= read line; do
		echo "--Running render ${queue_pos} on ${queue_len}..."
		echo "++" && echo "$line" && echo "++"
		eval "${line}" </dev/null
		tail -n +2 "${CONFIGDIR}/queue" > "${CONFIGDIR}/queue.tmp" && mv "${CONFIGDIR}/queue.tmp" "${CONFIGDIR}/queue"
		echo "--Render ended"
		queue_pos=`expr $queue_pos + 1`
	done < "${CONFIGDIR}/queue"
	exit 0
else
	echo "DEF IMPOSSIBLE if-else in main-end "
	exit 255
fi
echo "DEF IMPOSSIBLE in main-end "
exit 255
