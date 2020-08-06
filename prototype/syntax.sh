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

language_analyzer() {
	# if no file was given, do nothing
	if [ -z "$1" ]; then return; fi

	filepath=$1
	filename=$(basename $filepath)
	file_extension=${filename##*.}
	line_count=$(wc -l $filepath | cut -d' ' -f1)
	result_file=/tmp/language_analyzer

	# coloring scheme
	black=0
	red=1
	green=2
	yellow=3
	blue=4
	magenta=5
	cyan=6
	white=7

	# detect language from extension
	case $file_extension in
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
		Markdown|md)
			language=Markdown
			language_color=$cyan
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
			;;
	esac

	# restore previous line count
	previous_count=$(grep -E "^$language\ " $result_file | sed -r "s/^$language\ ([0-9]*)\ .*/\1/")
	#previous_count=$(awk '{print $2}' <<< "$list")

	# if the extension does not already exist in the result_file, add it
	if [ -z "$previous_count" ]; then
		previous_count=0;
		echo "$language 0 $language_color" >> $result_file
	fi

	# sum up the lines of this extension
	((line_count+=previous_count))
	sed -i -r "s/^($language)\ $previous_count\ ($language_color)$/\1\ $line_count\ \2/" $result_file
}

language_analyzer_result() {
	result_file=/tmp/language_analyzer

	# sum up all line counts
	sum=$(awk '{sum+=$2}END{print sum;}' /tmp/language_analyzer)

	# evaluage line counts in result_file
	gawk -i inplace -v sum=$sum '{percentage=$2*100/sum; printf "%s %.1f %s\n", $1, percentage, $3}' $result_file

	# sort the languages based on percentage
	sort -k2 -r -o $result_file $result_file

	# put the Other languages at the end if there are
	other=$(grep Other $result_file)
	if [ -n "$other" ]; then
		sed -i -e "/$other/d;\$a$other" $result_file
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
	done < /tmp/language_analyzer
	echo
	echo

	# write language names
	axis_length=40
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
	done < /tmp/language_analyzer
}

# make sure empty result_file exists
rm -f /tmp/language_analyzer
touch /tmp/language_analyzer

# make function accessible globally
export -f language_analyzer

# search files and add them to results
find $root -type f ! -name "*~" ! -name ".*~" ! -name "*.swp" ! -path '*/\.*' ! -executable > /tmp/analysis_files

while FS= read -r file; do
	language_analyzer $file
done < /tmp/analysis_files

# output the result
language_analyzer_result
