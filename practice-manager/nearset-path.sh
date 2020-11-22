#!/usr/bin/env bash

function index_page {
	local floor="${2:-1}"

	local depth=1
	local entry=
	local hierarchy=
	local index=
	page_index=
	page_hierarchy=

	for entry in ${1//\//$'\n'}
	do
		hierarchy="${hierarchy:-$entry}"

		if [ "$depth" -gt "$floor" ]
		then
			match="$(grep -n "$entry" "${hierarchy}/.index")"
			match="${match%%:*}"
			((match--)) # shift index down because of readme indexes
			index+="${match}."
		fi

		((depth++))
		hierarchy="${hierarchy}/${entry}"
	done
	page_index="$index"
	page_hierarchy="$hierarchy"
}

# requires path to page
# optional head/tail for direction of growth
function deepest_path {
	local hierarchy="${1%/}"
	local direction="${2:-up}"

	local entry=
	local tool=
	page_deepest=

	if [ "$direction" = "up" ]
	then
		tool="head"
	elif [ "$direction" = "down" ]
	then
		tool="tail"
	else
		return 1
	fi

	while true
	do
		if [ -d "$hierarchy" ] && [ -f "${hierarchy}/.index" ]
		then
			entry="$("$tool" -n1 "${hierarchy}/.index")"
			entry="${entry%% *}"
			if [ -n "$entry" ]
			then
				hierarchy="${hierarchy}/${entry}"
			else
				break
			fi
		else
			break
		fi
	done
	page_deepest="$hierarchy"
}

function nearset_path {
	local hierarchy="${1%/}"
	local page="${hierarchy##*/}"
	hierarchy="${hierarchy%/*}"
	local direction="${2:-up}"
	local match=
	local option=

	if [ "$direction" = "up" ]
	then
		option="-B1"
	elif [ "$direction" = "down" ]
	then
		option="-A1"
	else
		return 1
	fi

	while [ "$hierarchy" != "." ]
	do
		match="$(grep "$option" "$page" "${hierarchy}/.index")"

		if [ "$direction" = "up" ]
		then
			match="${match%$'\n'*}"
		else
			match="${match#*$'\n'}"
		fi

		if [ "$match" = "$page" ]
		then
			page="${hierarchy##*/}"
			hierarchy="${hierarchy%/*}"
		else
			if [ "$direction" = "up" ]
			then
				direction="down"
			else
				direction="up"
			fi

			if [ -d "${hierarchy}/${match}" ]
			then
				deepest_path "${hierarchy}/${match}" "$direction"
				page="$page_deepest"
			else
				page="${hierarchy}/${match}"
			fi
			index_page "$page"
			break
		fi
	done
}
