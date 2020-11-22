#!/usr/bin/env bash

# requires path to page
# optional head/tail for direction of growth
function deepest_path {
	local hierarchy="${1%/}"
	local direction="${2:-head}"
	local bottom_entry=
	
	local upper_entry=
	local delimiter=

	deepest_hierarchy=

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
	deepest_hierarchy="$hierarchy"
}

function index_page {
	local page="${1%.*}"
	page="${page##*/}"
	local depth=0
	local min_depth="${2:-1}"
	local entry=
	local hierarchy=
	local zero_padding=
	local local_index=
	local index_holder=
	local upper_hierarchy=
	local lower_hierarchy=
	local upper_entry=
	local lower_entry=
	local previous_bottom=
	local previous_top=
	local delimiter=
	index=
	next_index=
	previous_index=

	for entry in ${1//\//$'\n'}
	do
		if [ -n "$hierarchy" ]
		then
			hierarchy="${hierarchy}/${entry}"
		else
			hierarchy="$entry"
		fi

		if [ -z "$upper_hierarchy" ]
		then
			upper_hierarchy="$hierarchy"
		fi

		if [ -z "$lower_hierarchy" ]
		then
			lower_hierarchy="$hierarchy"
		fi

		if [ "$depth" -lt "$min_depth" ]
		then
			((depth++))
			continue
		fi

	set -x
		# always validate path step by step
		if [ -e "$upper_hierarchy" ]
		then
			# check if there is an entry above current entry
			upper_entry="$(grep -n -B1 "$entry" "${hierarchy%/*}/.index")"
			if [ "$(echo "$upper_entry" | wc -l)" -gt 1 ]
			then
				delimiter="-"
			else
				delimiter=":"
			fi
			upper_entry="${upper_entry%$'\n'*}"
			upper_entry="${upper_entry%% *}"
			local_index="${upper_entry%%$delimiter*}"
			upper_entry="${upper_entry#*$delimiter}"

			# grep returns same entry name when there is no above entry
			# so there is no above entry in the same depth
			# bottom entry in upper depth is appended into upper hierarchy
			# in order to keep upper entry as close to entry as possible
			if [ "$upper_entry" = "$entry" ]
			then
				previous_bottom="$(grep -n -B1 "${upper_entry}" "${upper_hierarchy}/.index")"
				if [ -z "$previous_bottom" ] && [ "${previous_index##*.}" -ne 0 ]
				then
					previous_index="${previous_index}.${zero_padding}0"
				else
					if [ "$(echo "$previous_bottom" | wc -l)" -gt 1 ]
					then
						delimiter="-"
					else
						delimiter=":"
					fi
					previous_bottom="${previous_bottom%%$'\n'*}"
					previous_bottom="${previous_bottom%% *}"
					if [ -n "$previous_index" ]
					then
						previous_index="${previous_index}.${previous_bottom%%$delimiter*}"
					else
						previous_index="${previous_bottom%%$delimiter*}"
					fi
					previous_bottom="${previous_bottom#*$delimiter}"
					upper_hierarchy="$upper_hierarchy/$previous_bottom"
				fi

			# there is an entry above current entry in the same depth
			# therefore, both upper and current hierarchies should lead the
			# same path so far, above entry now separates two hierarchies
			# and makes new branch until next depth is analyzed
			else
				upper_hierarchy="${hierarchy%/*}/$upper_entry"
				if [ -n "$previous_index" ]
				then
					# zero padding for one digit
					if [ ${#local_index} -eq 1 ]
					then
						previous_index="${index}${zero_padding}${local_index}"
					else
						previous_index="${index}${local_index}"
					fi
				else
					previous_index="${local_index%%:*}"
				fi
			fi
		# fail safe, if upper hierarchy goes wrong, exit with an error
		else
			tput bold
			echo "broken upper hierarchy in: $upper_hierarchy" >&2
			tput sgr0
			return 1
		fi
	set +x

		# always validate path step by step
		if [ -e "$lower_hierarchy" ]
		then
			# check if there is an entry above current entry
			lower_entry="$(grep -n -A1 "$entry" "${hierarchy%/*}/.index")"
			if [ "$(echo "$lower_entry" | wc -l)" -gt 1 ]
			then
				delimiter="-"
			else
				delimiter=":"
			fi
			lower_entry="${lower_entry#*$'\n'}"
			lower_entry="${lower_entry%% *}"
			local_index="${lower_entry%%$delimiter*}"
			lower_entry="${lower_entry#*$delimiter}"

			# grep returns same entry name when there is no above entry
			# so there is no above entry in the same depth
			# bottom entry in upper depth is appended into upper hierarchy
			# in order to keep upper entry as close to entry as possible
			if [ "$lower_entry" = "$entry" ]
			then
				previous_top="$(grep -n -A1 "${lower_entry}" "${lower_hierarchy}/.index")"
				if [ -z "$previous_top" ] && [ "${next_index##*.}" -ne 0 ]
				then
					next_index="${next_index}.${zero_padding}0"
				else
					if [ "$(echo "$previous_top" | wc -l)" -gt 1 ]
					then
						delimiter=":"
					else
						delimiter=":"
					fi
					previous_top="${previous_top%%$'\n'*}"
					if [ -n "$next_index" ]
					then
						next_index="${next_index}.${previous_top%%$delimiter*}"
					else
						next_index="${previous_top%%$delimiter*}"
					fi
					previous_top="${previous_top%% *}"
					previous_top="${previous_top#*$delimiter}"
					lower_hierarchy="$lower_hierarchy/$previous_top"
				fi

			# there is an entry above current entry in the same depth
			# therefore, both upper and current hierarchies should lead the
			# same path so far, above entry now separates two hierarchies
			# and makes new branch until next depth is analyzed
			else
				lower_hierarchy="${hierarchy%/*}/$lower_entry"
				if [ -n "$next_index" ]
				then
					# zero padding for one digit
					if [ ${#local_index} -eq 1 ]
					then
						next_index="${index}${zero_padding}${local_index}"
					else
						next_index="${index}${local_index}"
					fi
				else
					next_index="${local_index}"
				fi
			fi
		# fail safe, if upper hierarchy goes wrong, exit with an error
		else
			tput bold
			echo "broken lower hierarchy in: $lower_hierarchy" >&2
			tput sgr0
			return 1
		fi

		###### index 
		if [ -d "$hierarchy" ]
		then
			if ! [ -f "${hierarchy}/.index" ]
			then
				tput bold
				echo "hierarchy not indexed: $hierarchy" >&2
				tput sgr0
				return 1
			fi
		elif [ -f "$hierarchy" ]
		then
			if [ "$entry" = "README.md" ]
			then
				index="${index}${zero_padding}0."
				break
			fi

			index_holder="${hierarchy%/*}/.index"
			local_index="$(grep -c "$entry" $index_holder)"
			if [ "$local_index" -eq 0 ]
			then
				tput bold
				echo "page not indexed in hierarchy: $index_holder" >&2
				tput sgr0
				return 3
			elif [ "$local_index" -gt 1 ]
			then
				tput bold
				echo "duplicate entry in hierarchy: $index_holder" >&2
			fi
			index_holder=
			local_index=
		else
			tput bold
			echo "broken hierarchy: $hierarchy" >&2
			tput sgr0
			return 4
		fi

		match="$(grep -n "$entry" "${hierarchy%/*}/.index")"
		match="${match%%:*}"
		if [ "${#match}" -eq 1 ]
		then
			match="${zero_padding}${match}"
		fi
		index="${index}${match}."

		((depth++))
	done
	previous_index="${previous_index%.}."
	index="${index%.}."
	next_index="${next_index%.}."

	echo "upper hierarchy:$upper_hierarchy"
	echo "hierarchy:$hierarchy"
	echo "lower hierarchy:$lower_hierarchy"
	echo "previous index:$previous_index"
	echo "index:$index"
	echo "next index:$next_index"
}

index_page "$1"
