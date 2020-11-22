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
}
function gatherSub_F()
{
	:
}

function getSub_F()
{
	#echo "find $DIRPATH -regex '.*\.srt'"
	#echo $DIRPATH
	SUBFILES=`find $DIRPATH -regex '.*\.srt'`
	SUBSTRING="$4"
	for s in $SUBFILES; do
		echo "+++CICLO			$s"
		while [[ ! $REPLY =~ ^[ynax] ]]; do
			echo "File: $s"
			read -p "Aggiungere il subfile?[y|n|a|x]" -r -n 1 && echo
		done
		if [[ $REPLY = 'y' ]]; then
			echo "Aggiunta del file"
			if [[ -z $SUBSTRING ]]; then
				SUBSTRING="${s}"
			else
				SUBSTRING="${SUBSTRING},${s}"
			fi
			REPLY=''
		elif [[ $REPLY = 'n' ]]; then
			echo "File ignorato"
			REPLY=''
		elif [[ $REPLY = 'a' ]]; then
			echo "Aggiunta sequenziale:		$s"
			if [[ -z $SUBSTRING ]]; then
				SUBSTRING="${s}"
			else
				SUBSTRING="${SUBSTRING},${s}"
			fi
		elif [[ $REPLY = 'x' ]]; then
			echo "Ignora sequenziale:		$s"
		else
			echo "Impossible branch in getSub_F"
			exit -2
		fi
	done
	echo "++SUB FINALE"
	echo $SUBSTRING
}
##-----------------------
##-----------------------
echo "Definizione parametri..."
OUTPUT_DIR="/hdd/Render/Output"
FILEPATH=`realpath "$1"`
DIRPATH=`dirname $FILEPATH`
FILENAME=`echo "$FILEPATH"|sed 's|.*/\(.*\)\..*|\1|'`


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
if [[ -n $SUBSTRING ]]; then
	SUB="--srt-file $SUBSTRING"
fi
#--
#--LANCIO RENDER
echo HandBrakeCLI -i "$INPUT_FILE" -o "${OUTPUT_FILE}" $VIDEO $AUDIO $FILTERS $EXTRA $SUB "--verbose=0"
HandBrakeCLI -i "$INPUT_FILE" -o "${OUTPUT_FILE}" $VIDEO $AUDIO $FILTERS $EXTRA $SUB #"--verbose=0" 2> /dev/null

##TODO
#mettere versione ricorsiva per tutti i file in una cartella
