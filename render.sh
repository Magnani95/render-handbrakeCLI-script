#!/bin/bash
echo "Lancio..."
#--Param
if [[ $# < 3 ]]; then
	echo "Parametri errati: FILE QUALITY PRESET [SubFile]"
	exit 1
fi
#--Dir
FILEPATH=`realpath "$1"`
#echo $FILEPATH
if [[ ! $PWD = "/hdd/Render" ]]; then
	echo "Cambio cartella di lavoro in corso..."
	cd /hdd/Render
fi
#--
##FUN DEFINITION
echo "Definizione Funzioni..."
function filename_F()
{
	FILENAME=`echo "$INPUT_FILE" | sed 's|.*/\(.*\)\..*|\1.mkv|'`
}
function confirm_F()
{
	if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]];then
		echo "[SSH] il file esiste e non può essere sovrascritto"
		echo "[SSH] eliminarlo e riprovare"
		exit 1
	fi
	REPLY=""
	while [[ ! $REPLY =~ ^[yn] ]]; do
		read -p "Il file esiste già. Sovrascrivere?[y|n]" -r -n 1 && echo
	done
	if [[ $REPLY = 'y' ]]; then
		echo "Sovrascrivo..."
	else
		echo "Interruzione"
		exit 1
	fi
}
##-----------------------
##-----------------------
echo "Definizione parametri..."
INPUT_FILE="$FILEPATH"
#--
OUTPUT_FILE=`filename_F && echo "Output/${FILENAME}"`
if [[ -e $OUTPUT_FILE ]]; then
	confirm_F
fi
#--
QUALITY=$2
PRESET=$3
VIDEO="-e x265 -q $QUALITY --encoder-preset $PRESET"
AUDIO="--all-audio -E av_aac -6 dpl2 --all-subtitles "
FILTERS=''
EXTRA="-x pmode:pools=24" #"wpp:pools='thread count'"		#var=val:var=val
if [[ ! -z $4 ]]; then
	SUB="--srt-file $4"
fi
#--LANCIO RENDER
HandBrakeCLI -i "$INPUT_FILE" -o "${OUTPUT_FILE}" $VIDEO $AUDIO $FILTERS $EXTRA $SUB

##TODO
#mettere versione ricorsiva per tutti i file in una cartella
