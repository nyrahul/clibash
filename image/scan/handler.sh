image_scan_help()
{
	echo "image scan [options]"
	echo "      --spec | -s: Images to be scanned (regex can be specified)"
}

image_scan_cmd()
{
    # Remember to specify : in cases where argument is nessary both in short and long options
    OPTS=`getopt -o hs: --long "spec: help" -n 'parse-options' -- "$@"`
    eval set -- "$OPTS"
    while true; do
        case "$1" in
            -s | --spec ) spec="$2"; shift 2;;
            -h | --help ) image_scan_help; return; shift 1;;
            -- ) shift; break ;;
            * ) break ;;
        esac
    done
    echo "spec: $spec"
	echo "Executing image scan..."
}

