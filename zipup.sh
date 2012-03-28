#!/usr/bin/env bash
SCRIPT_NAME="zipup.sh"
SCRIPT_VERSION="1.1.7 2012-03-28"

usage() {
cat <<EOF
$SCRIPT_NAME $SCRIPT_VERSION
Quickly make archives of files and directories.

Usage: ${0##*/} [options] path ...

Options:
 -7, --7zip         Compress with 7-zip (requires 7z)
 -d, --date         Append the current date to the end of the filename
 -o, --output PATH  Directory to place the archive in (default is current
                    working directory)
 -h, --help         Show this help
EOF
}
FAIL() { [[ $1 ]] && echo "$SCRIPT_NAME: $1" >&2; exit ${2:-1}; }

opt_format="zip"
opt_date=
opt_date_format=%Y-%m-%d
opt_prefix_date="-"
opt_output="$PWD"

uniquefile() {
	local i=1
	local dir="$(dirname "$1")"
	local file="$(basename "$1")"
	local name="${file%.*}"
	local ext="${file##*.}"
	local try="$name"
	while [[ -e "$dir/$try.$ext" ]]; do
		((i++)); try="${name}${2:-.}${i}";
	done
	echo "$dir/$try.$ext"
}

processFile() {
	[[ ! -e "$1" ]] && return
	local file="$(basename "$1")"
	[[ -d "$1" ]] && file="$(cd "$1" &>/dev/null; basename "$PWD")"
	local out=$(uniquefile "${opt_output}/${file}${opt_date}.${opt_format}")
	if [[ ${opt_format} = "7z" ]]; then
		7z a "$out" "$1" || FAIL
	else
		zip -r "$out" "$1" || FAIL
	fi
}

while (($#)); do
	case $1 in
		-h|--help) usage; exit 0 ;;
		-7|--7zip) opt_format="7z" ;;
		-d|--date) opt_date="${opt_prefix_date}$(date +$opt_date_format)" ;;
		-o*|--output) [[ $1 =~ ^\-[a-z].+$ ]] && opt_output="${1:2}" || { opt_output=$2; shift; } ;;
		-*|--*) FAIL "unknown option ${1}" ;;
		*) break ;;
	esac
	shift
done

[[ ${#} < 1 ]] && ( usage; exit 0 )

[[ ! -d "$opt_output" ]] && FAIL "output is not a directory [$opt_output]"
[[ ! -w "$opt_output" ]] && FAIL "output directory is not writable [$opt_output]"

for f in "$@"; do
	processFile "$f"
done
