#!/bin/bash

# TODO
# - ForceMode should be FORCE+INPUT_ACCEPT+WRITE mode [-F -I -W]
# - sub search in subdir of file OR in cwd as distinct option
# - Queue for list of input-renders and for finished one.
# - All file in a directory

#BUG TO FIX

##FUN DEFINITION
echo "Function definition..."
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
	echo "-F|--force					Activate ForceMode"
	echo "-FI|--force-input				First input-file is selected"
	echo "-FO|--force-output				Overwrite output-file without prompt"
	echo "	QUEUE MANAGEMENT"
	echo "-Q|--queue					Create the queue file or print it"
	echo "-QA|--queue-add					Add current command to queue"
	echo "-QX|--queue-exec				Run sequentialy commands in queue(Implict --force-output)(Current command is not added)"
	echo
	echo "ForceMode: no input from user will be asked."
	echo "	- with --find-sub: all files found added"
}
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
			InputFiles+=("$1")
			shift;
			continue;
		fi
		param=$1
		case $param in
			#PARAM WITH VAL
			-q | --quality )
			Quality="$2"
			shift; shift;
			;;
			-p | --preset)
			Preset="$2"
			shift; shift;
			;;
			-s | --subtitle)
			SubString="$SubString""$2"
			shift; shift;
			;;
			# MODE FLAG
			-f | --find-sub)
			FindSub='TRUE'
			shift;
			;;
			-v | --verbose)
			QuietMode=''
			shift;
			;;
			-F | --force)
			ForceMode='TRUE'
			shift;
			;;
			-FI | --force-input)
			ForceMode_input='TRUE'
			shift;
			;;
			-FO | --force-output)
			ForceMode_output='TRUE'
			shift;
			;;
			#--Queue Management
			-Q | --queue)
			if [[ -e "${ConfigDir}/queue" ]]; then
				echo "Queue file exist" && echo "---"
				cat "${ConfigDir}/queue"
				exit 1
			else
				touch "${ConfigDir}/queue"
				echo "Queue file does not exist. It has been created."
				exit 1
			fi
			shift;
			;;
			-QA | --queue-add)
			QueueMode='ADD'
			shift;
			;;
			-QX | --queue-exec)
			QueueMode='RUN'
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
	if [[ -z ${InputFiles} && ${ForceMode} =~ 'FALSE' && !${QueueMode} =~ RUN ]]; then
		echo "Error, no Input file detected in parameters"
		exit 2
	fi
}
function get_input_file_F()
{
	for f in ${InputFiles[@]}; do
		REPLY=''

		if [[ -z ${InputName} ]]; then	#first assignment
			InputName=${f}
			if [[ $ForceMode == 'TRUE' ]]; then
				echo "ForceMode: the first file detected is set as input"
				break;
			else
				echo "'$f' is the file to render?"
				while [[ ! $REPLY =~ ^[ynYN] ]]; do
					read -p "Is that correct?[y|n]" -r -n 1 && echo
				done
				case $REPLY in
					y|Y)
					InputName=${f}
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
		else	#NOT first assignment
			echo "More than one input file"
			echo "Actual selection is: ${InputName}"
			echo "Other file is: ${f}"
			while [[ ! $REPLY =~ ^[ynYN] ]]; do
				read -p "Do you want to change actual file? [y|n]?" -r -n 1 && echo
			done
			case $REPLY in
				y|Y)
				InputName=${f}
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
	if [[ -z $InputName ]]; then
		echo "ERROR: No input file detected" && echo
		exit 1
	fi
	REPLY=''
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
		echo "File: $OutputFile"
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
	#echo "find $DirPath -regex '.*\.srt'"
	#echo $DirPath
	echo "$SubString"
	REPLY=''
	if [[ $FindSub =~ 'TRUE' ]]; then
		readarray  SubFiles < <(find "$DirPath" -type f -regex '.*\.srt' -print)

		for s in "${SubFiles[@]}"; do
			s=`echo "$s" | xargs `
			while [[ ! $REPLY =~ ^[ynax] ]]; do
				echo "File: $s"
				read -p "Add the subtitles file?[y|n|a|x]" -r -n 1 && echo
			done

			if [[ $REPLY = 'y' ]]; then
				echo "File added"
				if [[ -z $SubString ]]; then
					SubString="${s}"
				else
					SubString="${SubString},${s}"
				fi
				REPLY=''
			elif [[ $REPLY = 'n' ]]; then
				echo "File ignored"
				REPLY=''
			elif [[ $REPLY = 'a' ]]; then
				echo "Sequential adding:		$s"
				if [[ -z $SubString ]]; then
					SubString="${s}"
				else
					SubString="${SubString},${s}"
				fi
			elif [[ $REPLY = 'x' ]]; then
				echo "Sequential ignoring:		$s"
			else
				echo "DEF IMPOSSIBLE branch in getSub_F"
				exit 255
			fi
		done
		if [[ $QuietMode =~ 'FALSE' ]]; then
			echo "++FINAL Sub STRING"
			echo $SubString
		fi
	fi
	REPLY=''

}

function command_creation_F()
{
	get_input_file_F
	FilePath=`realpath "$InputName"`

	DirPath=`dirname "$FilePath"`
	FileName=`echo "$FilePath"|sed 's|.*/\(.*\)\..*|\1|'`
	echo "+dir: "$DirPath""
	echo "+file: "$FilePath""

	#--INPUT
	InputFile="$FilePath"
	if [[ ! -e $InputFile ]]; then
		echo "ERROR: the input file does not exists"
		exit 1
	fi
	#--OUTPUT FILE
	OutputFile="${Output_dir}${FileName}.mkv"
	if [[ -e $OutputFile ]]; then
		confirm_F
	fi
	#ENCODER SETTINGS
	Video="-e x265 -q $Quality --encoder-preset $Preset"
	Audio="--all-audio -E av_aac -6 dpl2 --all-subtitles "
	Filters=''
	Extra="-x pmode:pools='16'" #"wpp:pools='thread count'"		#var=val:var=val
	#--Sub
	getSub_F
	if [[ -n $SubString ]]; then
		Sub="--srt-file \""$SubString"\" "
	fi
	#--LANCIO RENDER
	command="HandBrakeCLI -i \""${InputFile}"\" -o \""${OutputFile}"\" $Video $Audio $Filters $Extra "${Sub}" $QuietMode"

}

##-----------------------
##----------MAIN-------------
echo "Variable definition..."
#--DEFAULT
InputName=''
Quality="23"
Preset="slow"
InputFiles=''
REPLY=''
#--Mode
FindSub='FALSE'
ForceMode='FALSE'
ForceMode_input='FALSE'
ForceMode_output='FALSE'
QuietMode="--verbose=0 2> /dev/null"
QueueMode='FALSE'
#--Directory
Output_dir="/hdd/Render/Output/"
ConfigDir='/hdd/Render/'
#--
argument_parsing_F "$@"

if [[ ${QueueMode} = 'FALSE' ]]; then
	command_creation_F "$@"
	echo "++" && echo "$command" && echo "++"
	eval "$command"
	exit 0
elif [[ ${QueueMode} = 'ADD' ]]; then
	command_creation_F "$@"
	echo "++" && echo "$command" && echo "++"
	echo "$command" >> "${ConfigDir}/queue"
	echo "Job added to the queue"
	exit 0
elif [[ ${QueueMode} = 'RUN' ]]; then
	queue_len=`cat ${ConfigDir}/queue | wc -l`
	queue_pos='1'
	printf "Queue lenght:\t ${queue_len}\n"
	#RENDER=`head -n 1 ${ConfigDir}/queue`
	while IFS= read line; do
		echo "--Running render ${queue_pos} on ${queue_len}..."
		echo "++" && echo "$line" && echo "++"
		eval "${line}" </dev/null
		tail -n +2 "${ConfigDir}/queue" > "${ConfigDir}/queue.tmp" && mv "${ConfigDir}/queue.tmp" "${ConfigDir}/queue"
		echo "--Render ended"
		queue_pos=`expr $queue_pos + 1`
	done < "${ConfigDir}/queue"
	exit 0
else
	echo "DEF IMPOSSIBLE if-else in main-end "
	exit 255
fi
echo "DEF IMPOSSIBLE in main-end "
exit 255
