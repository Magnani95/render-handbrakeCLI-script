#!/bin/bash
echo "Lancio..."
#--Param
if [[ $# < 3 ]]; then
	echo "Parametri errati: FILE QUALITY PRESET [SubFile,file,...]"
	exit 1
fi

##FUN DEFINITION
echo "Definizione Funzioni..."
function confirm_F()
{
	if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]];then
		echo "[SSH] il file esiste e non può essere sovrascritto"
		echo "[SSH] eliminarlo e riprovare"
		exit 1
	fi
	REPLY=""
	while [[ ! $REPLY =~ ^[yn] ]]; do
		echo "File: $OUTPUT_FILE"
		read -p "Il file esiste già. Sovrascrivere?[y|n]" -r -n 1 && echo
	done
	if [[ $REPLY = 'y' ]]; then
		echo "Sovrascrivo..."
	else
		echo "Interruzione"
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
	REPLY=''

	readarray  SUBFILES < <(find "$DIRPATH" -type f -regex '.*\.srt' -print)
	SUB_STRING="$4"
	echo "$SUB_STRING"
	for s in "${SUBFILES[@]}"; do
		s=`echo "$s" | xargs `
		while [[ ! $REPLY =~ ^[ynax] ]]; do
			echo "File: $s"
			read -p "Aggiungere il subfile?[y|n|a|x]" -r -n 1 && echo
		done
		if [[ $REPLY = 'y' ]]; then
			echo "Aggiunta del file"
			if [[ -z $SUB_STRING ]]; then
				SUB_STRING="${s}"
			else
				SUB_STRING="${SUB_STRING},${s}"
			fi
			REPLY=''
		elif [[ $REPLY = 'n' ]]; then
			echo "File ignorato"
			REPLY=''
		elif [[ $REPLY = 'a' ]]; then
			echo "Aggiunta sequenziale:		$s"
			if [[ -z $SUB_STRING ]]; then
				SUB_STRING="${s}"
			else
				SUB_STRING="${SUB_STRING},${s}"
			fi
		elif [[ $REPLY = 'x' ]]; then
			echo "Ignora sequenziale:		$s"
		else
			echo "Impossible branch in getSub_F"
			exit 2
		fi
	done
	echo "++SUB FINALE"
	echo $SUB_STRING
	REPLY=''
}
##-----------------------
##-----------------------
echo "Definizione parametri..."
OUTPUT_DIR="/hdd/Render/Output"
FILEPATH=`realpath "$1"`
DIRPATH=`dirname "$FILEPATH"`
FILENAME=`echo "$FILEPATH"|sed 's|.*/\(.*\)\..*|\1|'`
echo "dir: "$DIRPATH""
echo "file: "$FILEPATH""

INPUT_FILE="$FILEPATH"
#--OUTPUT FILE
OUTPUT_FILE="${OUTPUT_DIR}/${FILENAME}.mkv"
if [[ -e $OUTPUT_FILE ]]; then
	confirm_F
fi
#--
QUALITY=$2
PRESET=$3
VIDEO="-e x265 -q $QUALITY --encoder-preset $PRESET"
AUDIO="--all-audio -E av_aac -6 dpl2 --all-subtitles "
FILTERS=''
EXTRA="-x pmode:pools=16" #"wpp:pools='thread count'"		#var=val:var=val
#--SUB

getSub_F
if [[ -n $SUB_STRING ]]; then
	SUB="--srt-file \""$SUB_STRING"\" "
fi
#--
QUIET=''#"--verbose=0 2> /dev/null"
#--LANCIO RENDER
COMMAND="HandBrakeCLI -i \""${INPUT_FILE}"\" -o \""${OUTPUT_FILE}"\" $VIDEO $AUDIO $FILTERS $EXTRA "${SUB}" $QUIET"
echo "++" && echo"$COMMAND" && echo "++"
eval "$COMMAND"

##TODO
#mettere versione ricorsiva per tutti i file in una cartella
