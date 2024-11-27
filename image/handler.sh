image_help()
{
	cat << EOH
image [options]
      --label  | -l: Assets with label
      --period | -p: Time period for which the assets should be shown
EOH
}

image_cmd()
{
    # Remember to specify : in cases where argument is nessary both in short and long options
    OPTS=`getopt -o hp:l: --long "period: label: help" -n 'parse-options' -- "$@"`
    eval set -- "$OPTS"
    while true; do
        case "$1" in
            -p | --period ) timeperiod="$2"; shift 2;;
            -l | --label ) label="$2"; shift 2;;
            -h | --help ) image_help; return; shift 1;;
            -- ) shift; break ;;
            * ) break ;;
        esac
    done
    echo "timeperiod: $timeperiod"
    echo "label: $label"
	echo "Executing image..."
}
