#!/bin/bash
# saner programming env: these switches turn some bugs into errors

preStr="\providecommand{\main}"
make_path () { # $1 is dir $2 is level
	if [ $2 -eq 0 ]
	then
		curPath="."
	else
		curPath=".."
		if [ $2 -gt 1 ]
		then
			cnt=$2
			until [ $cnt -eq 1 ]
			do
				curPath="${curPath}/.."
				((cnt--))
			done
		fi
	fi
	filePath="${1}/.path.tex"
	echo "% in dir ${1}" >| ${filePath}
	echo "${preStr}{${curPath}}" >> ${filePath}
	for u in "${1}/"*
	do
		if [ -d ${u} ]
		then
			make_path ${u} $(( $2 + 1 ))
		fi
	done
}

set -o errexit -o pipefail -o noclobber -o nounset

# -allow a command to fail with !’s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

OPTIONS=fph
LONGOPTS=fast,path,help

# -regarding ! and PIPESTATUS see above
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

f=n
p=n
h=n
while true; do
	case "$1" in
		-f|--fast)
			f=y
			shift
			;;
		-p|--path)
			p=y
			shift
			;;
		-h|--help)
			h=y
			shift
			;;
		--)
			shift
			break
			;;
		*)
			echo "Eprogramming error"
			exit 3
			;;
	esac
done

if [ $h = n ]; then
	if [ $p = y ]
		then
		make_path "." 0
	fi
	pdflatex -shell-escape Main.tex
	if [ $f = n ]
		then
			bibtex Main
			pdflatex -shell-escape Main.tex
			pdflatex -shell-escape Main.tex
	fi
else
	echo -e \
"List of commands:\n\
-f\t--fast\tDoes not run full compile run, usefull if only checking layout\n\
-p\t--path\tWill create '.path.tex' files in every subdirectory\n\
-h\t--help\tThis help"

fi
