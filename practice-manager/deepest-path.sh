#!/usr/bin/env bash

# requires path to page
# optional head/tail for direction of growth
function deepest_path {
	local hierarchy="${1%/}"
	local direction="${2:-head}"

	local bottom_entry=
	local upper_entry=
	local delimiter=

	while [ 1 = 1 ]
	do
		if [ -d "$hierarchy" ] && [ -f "${hierarchy}/.index" ]
		then
			bottom_entry="$("$direction" -n1 "${hierarchy}/.index")"
			bottom_entry="${bottom_entry%% *}"
			if [ -n "$bottom_entry" ]
			then
				hierarchy="${hierarchy}/${bottom_entry}"
			else
				break
			fi
		else
			break
		fi
	done
echo "$hierarchy"
}

deepest_path "$1" "$2"
