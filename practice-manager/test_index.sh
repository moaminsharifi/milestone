#!/usr/bin/env bash

tests=0
passed=0
failed=0

function parse_response {
	upper_hierarchy="$(echo "$1" | sed -n '/^upper hierarchy:/s/.*://p')"
	hierarchy="$(echo "$1" | sed -n '/^hierarchy:/s/.*://p')"
	lower_hierarchy="$(echo "$1" | sed -n '/^lower hierarchy:/s/.*://p')"
	previous_index="$(echo "$1" | sed -n '/^previous index:/s/.*://p')"
	index="$(echo "$1" | sed -n '/^index:/s/.*://p')"
	next_index="$(echo "$1" | sed -n '/^next index:/s/.*://p')"
}

function validate_response {
	if [ "$upper_hierarchy" = "$1" ] && \
		[ "$hierarchy" = "$2" ] && \
		[ "$lower_hierarchy" = "$3" ] && \
		[ "$previous_index" = "$4" ] && \
		[ "$index" = "$5" ] && \
		[ "$next_index" = "$6" ]
	then
		echo -n "."
		((passed++))
	else
		echo -n "E"
		((failed++))
	fi
	((tests++))
}

function analyze {
	echo
	printf "%0.s-" $(seq 0 "$tests")
	echo
	echo "tests: $tests"
	echo "passed: $passed"
	echo "failed: $failed"
	echo
	if [ "$tests" -eq "$passed" ]
	then
		tput setaf 2
		echo "passed"
		tput sgr0
	else
		tput bold
		echo "failed"
		tput sgr0
	fi
	echo
}

parse_response "$(./index.sh ./sample/section1/chapter1/practice1.c)"
validate_response "./sample/section1/chapter1/practice1.c" \
	"./sample/section1/chapter1/practice1.c" \
	"./sample/section1/chapter2/practice1.c" \
	"1.1.1.1." \
	"1.1.1.1." \
	"1.1.2.1."

parse_response "$(./index.sh ./sample/section1/chapter2/sample.c)"
validate_response "./sample/section1/chapter2/practice2.c" \
	"./sample/section1/chapter2/sample.c" \
	"./sample/section1/chapter2/practice4.c" \
	"1.1.2.2." \
	"1.1.2.3." \
	"1.1.2.4."

###############################################################################
analyze
