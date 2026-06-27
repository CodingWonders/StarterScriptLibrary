#!/bin/bash

function getLine() {
    line=$1
    file=$2
    # https://community.unix.com/t/extract-a-line-from-a-file-using-the-line-number/163887/3
    echo $(sed $line!d "$file")
}

function getItemProperty() {
    line=$1
    file=$2
    echo $(getLine $line "$file" | cut -f2- -d:)
}

function readScript() {
    scriptFile="$1"

    if ! [ -f "$scriptFile" ]; then
        # The file does not exist.
        return
    fi
    
    # The starter script header contains 4 lines:
    # - Language
    # - Name
    # - Description
    # - Customizable?
    # Windows likes to use CRLF, which is not nice for the UNIX parser; get rid
    # of the carriage returns
    dtssLang=$(getItemProperty 1 "$1" | tr -d " " | tr -d '\r')
    dtssName=$(getItemProperty 2 "$1" | sed 's/^[[:space:]]*//' | tr -d '\r')
    dtssDesc=$(getItemProperty 3 "$1" | sed 's/^[[:space:]]*//' | tr -d '\r')
    dtssCust=$(getItemProperty 4 "$1" | cut -f2 -d? | tr -d " " | tr -d '\r')
    
    echo -e "    {"
    echo -e "        \"language\": \"$dtssLang\","
    echo -e "        \"name\": \"$dtssName\","
    echo -e "        \"description\": \"$dtssDesc\","
    echo -e "        \"customizable\": \"$dtssCust\","
    echo -e "        \"fileName\": \"$(basename "$scriptFile")\""
    echo -en "    }"
}

if [ $# -lt 1 ]; then
    echo "Please provide one or more starter scripts to process and try again. Press any"
    echo "key to exit . . ."
    read -sn1
else
    # Begin writing the JSON
    echo -e "\"scripts\": ["
    for dtss in "$*"; do
        if [ -d "$dtss" ]; then
	    # Get file count to determine when to stop appending commas
	    lines=$(ls -lA "$dtss"/*.dtss | wc -l)
	    fileIdx=0
	    for file in "$dtss"/*.dtss; do
	        readScript "$file"
		fileIdx=$(($fileIdx+1))
		if [ $fileIdx -lt $lines ]; then
		    echo -n ","
		fi
		echo -en "\n"
	    done
	else
	    readScript "$dtss"
	fi
    done
    echo -e "]"
fi
