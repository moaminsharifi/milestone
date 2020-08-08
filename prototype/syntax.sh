#!/bin/bash

if [ $# -eq 0 ]; then
	tput bold
	echo "Usage: $0 </path/to/directory>"
	tput sgr0
	exit 1
elif [ -f $1 ]; then
	directory=$(dirname $1)
else
	directory=$1
fi

## Result string will be stored in this variable.
## Records are delimited by : character and are stacked in one line.
## RS=":" (Record Seperator)
## FS="," (Field Seperator)
## Fields: "language name,line count,coloring scheme"
## e.g. "Python,163,6:HTML,1457,1:CSS,640,5:JavaScript,316,3"
result=

## This function is called for each file existing in the given directory.
## Languages are detected based on file extension (maybe syntax later).
## Counts lines of given file and stores in result.
## Currently this function is inefficient and has performance penalty.
file_analyzer() {
	filepath=$1
	filename=${filepath##*/}
	file_extension=${filename##*.}
	line_count=$(wc -l "$filepath" | cut -d' ' -f1)

	# detect language from extension
	case $file_extension in
		[mM]akefile)
			language=Makefile
			language_color=0 #black
			;;
		asm|[sS]|sx)
			language=Assembly
			language_color=4 #blue
			;;
		[cC]|[hH]|i)
			language=C
			language_color=5 #magenta
			;;
		c++|cxx|[cC][pP][pP]|[hH][pP][pP]|hxx|cu|cc|ii|cp|hh|h++|tcc)
			language=Cxx
			language_color=1 #red
			;;
		sh)
			language=Shell
			language_color=2 #green
			;;
		py)
			language=Python
			language_color=6 #cyan
			;;
		html|htm|[a-z]html)
			language=HTML
			language_color=1 #red
			;;
		js)
			language=JavaScript
			language_color=3 #yellow
			;;
		css)
			language=Css
			language_color=6 #magenta
			;;
		tex)
			language=TeX
			language_color=2 #green
			;;
		*)
			# ignore unknown languages
			return
			;;
	esac

	## query the number of lines written in this language, if it already exists.
	previous_count=$(awk -v language=$language 'BEGIN{FS=",";RS=":"} $1==language {print $2}' <<< "$result")

	# if this language does not already exist from previous query, add it
	if [ -z "$previous_count" ]; then
		previous_count=0
		result="$language,0,$language_color:$result"
	fi

	# add up the line count for this language
	((line_count+=previous_count))
	result=$(awk -v language="$language" -v count=$line_count 'BEGIN{FS=",";OFS=",";RS=":";ORS=":"} $1==language {$2=count} NF==3' <<< "$result")
}

## This function prints the language bar.
## Evaluates the usage percentage of each language.
## 
display_bar() {
	# store the sum of lines in all affected languages for later use
	sum=$(awk 'BEGIN{FS=",";RS=":"} {sum+=$2} END{print sum;}' <<< "$result")

	if [ $sum -eq 0 ]; then
		tput bold
		echo "No output"
		tput sgr0
		return 3
	fi

	# FIXME: remove the last useless colon in result
	result=$(sed 's/:$//' <<< "$result")

	# evaluage usage percentage of each language
	result=$(awk -v sum=$sum 'BEGIN{FS=",";OFS=",";RS=":";ORS=":"} {percentage=$2*100/sum; printf "%s,%.1f,%s\n", $1, percentage, $3}' <<< "$result")

	# sort the languages based on percentage
	result=$(echo "$result" | tr ':' '\n' | sort -t, -k2 -r -h | sed '/^$/d' | tr '\n' ':')

	# FIXME: remove the last useless colon in result
	result=$(sed 's/:$//' <<< "$result")

	echo -e "Languages\n"

	# draw language bar
	block=$(echo -e "\u2588")
	awk -v block="$block" -v axis=40 'BEGIN{FS=",";RS=":"} {system("tput setaf " $3); for(c=0;c<$2*axis/100;c++) printf "%s",block}' <<< "$result"
	tput sgr0
	echo
	echo

	# write language names
	block=$(echo -e "\u25cf")
	awk -v block="$block" -v axis=40 'BEGIN{FS=",";RS=":"} {system("tput setaf " $3); printf "%s %s ", block, $1; system("tput sgr0"); system("tput dim"); printf "%%%.1f\n", $2}' <<< "$result"
	tput sgr0
}

language_analyzer() {
	# make this function accessible globally
	export -f file_analyzer

	# search files for language detection
	find $directory -type f -not -path '*/\.*' > /tmp/record
	while FS= read -r file; do
		file_analyzer "$file"
	done < /tmp/record

	# output the result
	display_bar
}

language_analyzer
