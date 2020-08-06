#!/bin/bash

if [ $# -ne 1 ]; then
	echo "no path given"
	exit
elif ! [ -d $1 ]; then
	echo "invalid path given"
	exit
elif [ -f $1 ]; then
	root=$(dirname $1)
else
	root=$1
fi

# coloring scheme
black=0
red=1
green=2
yellow=3
blue=4
magenta=5
cyan=6
white=7

result=
language_analyzer() {
	filepath=$1
	filename=${filepath##*/}
	file_extension=${filename##*.}
	line_count=$(wc -l "$filepath" | cut -d' ' -f1)

	# detect language from extension
	case $file_extension in
		md)
			language=Markdown
			language_color=$cyan
			;;
		[mM]akefile)
			language=Makefile
			language_color=$black
			;;
		asm)
			language=Assembly
			language_color=$blue
			;;
		c|h)
			language=C
			language_color=$magenta
			;;
		c++|cxx|cpp|hpp|hxx|cu)
			language=Cxx
			language_color=$red
			;;
		sh)
			language=Shell
			language_color=$green
			;;
		py)
			language=Python
			language_color=$blue
			;;
		html|htm)
			language=HTML
			language_color=$red
			;;
		tex)
			language=TeX
			language_color=$green
			;;
		js)
			language=JavaScript
			language_color=$yellow
			;;
		*)
			language=Other
			language_color=$white
			return
			;;
	esac

	# restore previous line count
	previous_count=$(awk -v language=$language 'BEGIN{ RS=":" } $1==language {print $2}' <<< "$result")

	# if the extension does not already exist in the result, add it
	if [ -z "$previous_count" ]; then
		previous_count=0;
		result="$language 0 $language_color:$result"
	fi

	# sum up the lines of this extension
	((line_count+=previous_count))
	result=$(echo "$result" | awk -v language="$language" -v count=$line_count 'BEGIN{RS=":"; ORS=":"} $1==language {$2=count} NF==3')
}

language_analyzer_result() {
	# sum up all line counts
	sum=$(awk 'BEGIN{RS=":"} {sum+=$2} END{print sum;}' <<< "$result")

	if [ $sum -eq 0 ]; then
		tput bold
		echo "no output"
		tput sgr0
		return
	fi

	# evaluage line counts in result
	# fixme
	result=$(echo "$result" | sed 's/:$//')
	result=$(echo "$result" | awk -v sum=$sum 'BEGIN{RS=":"} {percentage=$2*100/sum; printf "%s %.1f %s\n", $1, percentage, $3}')

	# sort the languages based on percentage
	result=$(echo "$result" | tr ':' '\n' | sort -k2 -r -h | sed '/^$/d' | tr '\n' ':')

	# put the Other languages at the end if there are
	other=$(awk 'BEGIN{RS=":"} $1=="Other"' <<< "$result")
	if [ -n "$other" ]; then
		#result=$(echo "$result" | tr ':' '\n' | sed "/$other/d;\$a$other" | tr '\n' ':')
		result=$(echo "$result" | tr ':' '\n' | sed "/$other/d" | tr '\n' ':')
	fi

	echo "Languages"
	echo

	# draw the colored block line
	axis_length=40
	while FS= read -r line; do
		language=$(cut -d' ' -f1 <<< "$line")
		percentage=$(cut -d' ' -f2 <<< "$line")
		color=$(cut -d' ' -f3 <<< "$line")
		line_length=$(echo "$percentage * $axis_length / 100" | bc)
		tput setaf $color
		printf "%0.s\u2588" $(seq 1 $line_length)
		tput sgr0
	done <<< $(echo "$result" | tr ':' '\n' | sed '/^$/d')
	echo
	echo

	# write language names
	while FS= read -r line; do
		language=$(cut -d' ' -f1 <<< "$line")
		percentage=$(cut -d' ' -f2 <<< "$line")
		color=$(cut -d' ' -f3 <<< "$line")
		line_length=$(echo "$percentage * $axis_length / 100" | bc)
		tput setaf $color
		echo -ne "\u25cf "
		tput sgr0
		echo -n "$language "
		tput dim
		echo $percentage
		tput sgr0
	done <<< $(echo "$result" | tr ':' '\n' | sed '/^$/d')
}

language_graph() {
	# make function accessible globally
	export -f language_analyzer

	# search files and add them to results
	find $root -type f -not -path '*/\.*' -not -executable > /tmp/language_analyzer
	while FS= read -r file; do
		language_analyzer "$file"
	done < /tmp/language_analyzer

	# output the result
	language_analyzer_result
}

language_graph
