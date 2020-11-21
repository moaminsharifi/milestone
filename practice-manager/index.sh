#!/usr/bin/env bash

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

		# always validate path step by step
		if [ -e "$upper_hierarchy" ]
		then
			# check if there is an entry above current entry
			upper_entry="$(grep -n -B1 "$entry" "${hierarchy%/*}/.index")"
			upper_entry="${upper_entry#*:}"
			upper_entry="${upper_entry%$'\n'*}"
			upper_entry="${upper_entry%% *}"

			# grep returns same entry name when there is no above entry
			# so there is no above entry in the same depth
			# bottom entry in upper depth is appended into upper hierarchy
			# in order to keep upper entry as close to entry as possible
			if [ "$upper_entry" = "$entry" ]
			then
				previous_bottom="$(grep -B1 "${upper_entry}" "${upper_hierarchy}/.index")"
				previous_bottom="${previous_bottom%%$'\n'*}"
				previous_bottom="${previous_bottom%% *}"
				upper_hierarchy="$upper_hierarchy/$previous_bottom"

			# there is an entry above current entry in the same depth
			# therefore, both upper and current hierarchies should lead the
			# same path so far, above entry now separates two hierarchies
			# and makes new branch until next depth is analyzed
			else
				upper_hierarchy="${hierarchy%/*}/$upper_entry"
			fi
		# fail safe, if upper hierarchy goes wrong, exit with an error
		else
			tput bold
			echo "broken upper hierarchy in: $upper_hierarchy" >&2
			tput sgr0
			return 1
		fi

		# always validate path step by step
		if [ -e "$lower_hierarchy" ]
		then
			# check if there is an entry above current entry
			lower_entry="$(grep -A1 "$entry" "${hierarchy%/*}/.index")"
			lower_entry="${lower_entry#*$'\n'}"
			lower_entry="${lower_entry%% *}"

			# grep returns same entry name when there is no above entry
			# so there is no above entry in the same depth
			# bottom entry in upper depth is appended into upper hierarchy
			# in order to keep upper entry as close to entry as possible
			if [ "$lower_entry" = "$entry" ]
			then
				previous_top="$(grep -A1 "${lower_entry}" "${lower_hierarchy}/.index")"
				previous_top="${previous_top##*$'\n'}"
				previous_top="${previous_top%% *}"
				lower_hierarchy="$lower_hierarchy/$previous_top"

			# there is an entry above current entry in the same depth
			# therefore, both upper and current hierarchies should lead the
			# same path so far, above entry now separates two hierarchies
			# and makes new branch until next depth is analyzed
			else
				lower_hierarchy="${hierarchy%/*}/$lower_entry"
			fi
		# fail safe, if upper hierarchy goes wrong, exit with an error
		else
			tput bold
			echo "broken lower hierarchy in: $lower_hierarchy" >&2
			tput sgr0
			return 1
		fi

		##### upper index
		if [ -d "$upper_hierarchy" ]
		then
			if ! [ -f "${upper_hierarchy}/.index" ]
			then
				tput bold
				echo "upper hierarchy not indexed: $upper_hierarchy" >&2
				tput sgr0
				return 1
			fi
		elif [ -f "$upper_hierarchy" ]
		then
			if [ "$entry" = "README.md" ]
			then
				previous_index="${previous_index}${zero_padding}0."
				break
			fi

			index_holder="${upper_hierarchy%/*}/.index"
			local_index="$(grep -c "$upper_entry" $index_holder)"
			if [ "$local_index" -eq 0 ]
			then
				tput bold
				echo "page not indexed in upper hierarchy: $index_holder" >&2
				tput sgr0
				return 3
			elif [ "$local_index" -gt 1 ]
			then
				tput bold
				echo "duplicate entry in upper hierarchy: $index_holder" >&2
			fi
			index_holder=
			local_index=
		else
			tput bold
			echo "broken upper hierarchy: $upper_hierarchy" >&2
			tput sgr0
			return 4
		fi

		match="$(grep -n "$upper_entry" "${upper_hierarchy%/*}/.index")"
		match="${match%%:*}"
		if [ "${#match}" -eq 1 ]
		then
			match="${zero_padding}${match}"
		fi
		previous_index="${previous_index}${match}."

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

		##### lower index
		if [ -d "$lower_hierarchy" ]
		then
			if ! [ -f "${lower_hierarchy}/.index" ]
			then
				tput bold
				echo "lower hierarchy not indexed: $lower_hierarchy" >&2
				tput sgr0
				return 1
			fi
		elif [ -f "$lower_hierarchy" ]
		then
			if [ "$lower_entry" = "README.md" ]
			then
				next_index="${next_index}${zero_padding}0."
				break
			fi

			index_holder="${lower_hierarchy%/*}/.index"
			local_index="$(grep -c "$lower_entry" $index_holder)"
			if [ "$local_index" -eq 0 ]
			then
				tput bold
				echo "page not indexed in lower hierarchy: $index_holder" >&2
				tput sgr0
				return 3
			elif [ "$local_index" -gt 1 ]
			then
				tput bold
				echo "duplicate entry in lower hierarchy: $index_holder" >&2
			fi
			index_holder=
			local_index=
		else
			tput bold
			echo "broken lower hierarchy: $lower_hierarchy" >&2
			tput sgr0
			return 4
		fi

		match="$(grep -n "$lower_entry" "${lower_hierarchy%/*}/.index")"
		match="${match%%:*}"
		if [ "${#match}" -eq 1 ]
		then
			match="${zero_padding}${match}"
		fi
		next_index="${next_index}${match}."

		((depth++))
	done
	previous_index="${previous_index%.}"
	index="${index%.}"
	next_index="${next_index%.}"

	echo "upper hierarchy:$upper_hierarchy"
	echo "hierarchy:$hierarchy"
	echo "lower hierarchy:$lower_hierarchy"
}

index_page "$1"
echo "previous index:$previous_index"
echo "index:$index"
echo "next index:$next_index"
