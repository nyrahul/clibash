#!/bin/bash

CLIOUT="cli"
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
	[[ ! -f "$1" ]] && logerr "[$1] file not found" && return
	cat <<EOH >> $CLIOUT
read -r -d '' filecontent <<EOR
$(cat $1 | sed -e 's/\$/\\\$/g' -e 's/`/\\`/g')
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
	--include | -i: Include/source script files that might be needed for all the command handlers. [optional]
EOH
}

declare -a srcfiles
parseargs()
{
    # Remember to specify : in cases where argument is nessary both in short and long options
    OPTS=`getopt -o ho:i: --long "out: include: help" -n 'parse-options' -- "$@"`
    eval set -- "$OPTS"
    while true; do
        case "$1" in
			-i | --include ) srcfiles+=($2); shift 2;;
            -o | --out ) CLIOUT="$2"; shift 2;;
            -h | --help ) image_help; return; shift 1;;
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
	. ./.cfg.mk
	cat <<EOH >> $CLIOUT
	"version")
		echo "version: $(echo $VERSION)"
		echo "build date: $(date)"
		echo "build location: $(uname -a)"
		;;
EOH

	# help option
	cat << EOH >> $CLIOUT
	* | help)
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
for src in ${srcfiles[*]}; do
	source_file $src
done
source_level "./"
logdbg "List of commands: ${cmdarr[*]}"
handle_cmds
