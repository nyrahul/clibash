image_list_help()
{
	echo "image list [options]"
	echo "      --filter | -f: image list filters"
	echo "      --label  | -l: image assets with label"
}

image_list_cmd()
{
    # Remember to specify : in cases where argument is nessary both in short and long options
    OPTS=`getopt -o hf:l: --long "filter: label: help" -n 'parse-options' -- "$@"`
    eval set -- "$OPTS"
    while true; do
        case "$1" in
            -f | --filter ) filter="$2"; shift 2;;
            -l | --label ) label="$2"; shift 2;;
            -h | --help ) image_list_help; return; shift 1;;
            -- ) shift; break ;;
            * ) break ;;
        esac
    done
    echo "filter: $filter"
    echo "label: $label"
	echo "Executing image list..."
}

