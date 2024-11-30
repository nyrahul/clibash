#!/bin/bash

CLIOUT="${CLIOUT:-cli}"
VERSION="${VERSION:-v0.1}"
cli_add_header()
{
	cat <<EOH >$CLIOUT
#!/bin/bash

# This is an auto-generated file. Tread with caution!

EOH
	chmod +x $CLIOUT
}

LOGLEVEL=${LOGLEVEL:-1} #0=logdbg, 1=loginfo, 2=logwarn, 3=logerr
logdbg()
{
	[[ $LOGLEVEL -gt 0 ]] && return
	echo "$*"
}
loginfo()
{
	[[ $LOGLEVEL -gt 1 ]] && return
	echo "$*"
}
logwarn()
{
	[[ $LOGLEVEL -gt 2 ]] && return
	echo "$*"
}
logerr()
{
	[[ $LOGLEVEL -gt 3 ]] && return
	echo "$*"
}

declare -a cmdarr
source_file()
{
	content=""
	if [[ $1 =~ http* ]]; then # source contents from a URL
		content=$(curl -s $1)
	elif [ -f "$1" ]; then # Source contents from a file
		content=$(cat $1)
	fi
	[[ "$content" == "" ]] && echo "could not fetch contents from [$1]" && return 1
	cat <<EOH >> $CLIOUT
read -r -d '' filecontent <<EOR
$(echo "$content" | sed -e 's/\$/\\\$/g' -e 's/`/\\`/g')
EOR
. <(echo "\$filecontent")
EOH
}

source_level()
{
	for cmdpath in `ls -d $1*/ 2>/dev/null | sort`; do
		cmd="$2$(basename $cmdpath)"
		cmdhandler="${cmdpath}handler.sh"
		[[ ! -f "$cmdhandler" ]] && logdbg "skipping dir [$cmd], no handler.sh found ..." && continue
		echo "# ----------- [$cmd] command handler -----------------------" >> $CLIOUT
		source_file $cmdhandler
		echo "# ----------- end of [$cmd] command handler ----------------" >> $CLIOUT
		cmdarr+=($cmd)
		source_level $cmdpath ${cmd}_
	done
}

helpme()
{
	cat <<EOH
$0 [options]
	--out | -o: Output cli executable script file to generate. [default: $CLIOUT]
	--cliversion: Version to set for the generated cli. [default: $VERSION]
	--include | -i: Include/source script files that might be needed for all the command handlers. [optional]
EOH
}

parseargs()
{
    # Remember to specify : in cases where argument is nessary both in short and long options
    OPTS=`getopt -o ho:i: --long "cliversion: out: include: help" -n 'parse-options' -- "$@"`
    eval set -- "$OPTS"
    while true; do
        case "$1" in
			-i | --include ) INC_SH="$2"; shift 2;;
            -o | --out ) CLIOUT="$2"; shift 2;;
            --cliversion ) VERSION="$2"; shift 2;;
            -h | --help ) helpme; exit 2;;
            -- ) shift; break ;;
            * ) break ;;
        esac
    done
}

handle_cmds()
{
	cat <<EOH >> $CLIOUT

# Processing starts here ...
unset cmd
while true; do
	[[ \${1:--} == -* ]] && break #if arg is empty or starts with '-'
	[[ "\$cmd" != "" ]] && cmd="\${cmd}_"
	cmd="\$cmd\$1"
	shift
done
case "\$cmd" in
EOH
	for cmd in ${cmdarr[*]}; do
		echo -en "\t\"$cmd\")\n" >> $CLIOUT
		cat <<EOH >> $CLIOUT
		${cmd}_cmd "\$@"
		;;
EOH
	done

	# version option
	cat <<EOH >> $CLIOUT
	"version")
		echo "version: $(echo $VERSION)"
		;;
EOH

	# help option
	cat << EOH >> $CLIOUT
	* | help)
		[[ "\$(type -t clilogo)" == "function" ]] && clilogo
		echo "# \$0 command options"
		echo "\\\`\\\`\\\`"
		echo "\$0"
EOH
	for cmd in ${cmdarr[*]}; do
		cat <<EOH >> $CLIOUT
		echo -en "\\t${cmd//_/ }\\n"
EOH
	done
	cat <<EOH >> $CLIOUT
		echo -en "\\tversion\\n"
		echo -en "\\thelp\\n"
		echo "\\\`\\\`\\\`"

EOH
	for cmd in ${cmdarr[*]}; do
		cat <<EOH >> $CLIOUT
		${cmd}_help
EOH
	done
	echo -en "\t\t;;\nesac" >> $CLIOUT
}

parseargs $*
cli_add_header
[[ -f "logo.sh" ]] && echo "sourcing logo ..." && source_file "logo.sh"
source_file "https://raw.githubusercontent.com/nyrahul/argutil/refs/heads/main/argutil.sh"
for src in `echo $INC_SH`; do
	loginfo "including source [$src] ..."
	source_file $src
done
source_level "./"
loginfo "sourced commands: ${cmdarr[*]}"
handle_cmds
