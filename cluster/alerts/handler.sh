clusterjq='.[] | select(.ClusterName|test("idt")'
alertjq='.'
stimestr="2 days ago"
stime=$(date -d "$stimestr" +%s)
etime=$(date +%s)
alerttype="kubearmor"
filters=""

cluster_alerts_help()
{
	cat <<EOH
### [cluster alerts] command

Options supported:
* --clusterjq [jq-spec]: jq filter to be used on cluster list output (default: '$clusterjq')
* --alertjq [jq-spec]: jq filter to be used on cluster list output (default: '$alertjq')
* --stime [datetime]: start time in epoch format (default: '$stime', $stimestr)
* --etime [datetime]: end time in epoch format (default: '$etime', now)
* --type [alert-type]: alert-type (default: "$alerttype")
* --filters [filter-spec]: Alert filters to be passed to API (default: '$filters')

Examples:
1. knoxcli cluster alerts --alertjq '.response[] | select(.Resource // "unknown" | test("ziggy"))' <br>
	... list all the alerts containing 'ziggy' in the Resource filter
2. knoxcli cluster alerts --filters '{"field":"HostName","value":"store54055","op":"match"}' --alertjq '.response[] | "hostname=\(.HostName),resource=\(.Resource//""),UID=\(.UID),operation=\(.Operation)"' <br>
	... get all alerts for HostName="store54055" and print the response in following csv format hostname,resource,UID,operation

> Difference between --alertjq and --filters? <br>
> --filters are passed directly to the AccuKnox API. --alertjq operates on the output of the AccuKnox API response. It is recommended to use --filters as far as possible. However, you can use regex/jq based matching criteria with --alertjq.

EOH
}

cluster_alerts_query()
{
	for((pgid=1;;pgid++)); do
		data_raw="{\"Namespace\":[],\"FromTime\":$stime,\"ToTime\":$etime,\"PageId\":$pgid,\"PageSize\":50,\"Filters\":[$filters],\"ClusterID\":[$cidlist],\"View\":\"List\",\"Type\":\"$alerttype\",\"WorkloadType\":[],\"WorkloadName\":[],\"WorkspaceID\":$TENANT_ID}"
		ak_api "$CWPP_URL/monitors/v1/alerts/events?orderby=desc"
		acnt=$(echo $json_string | jq '.response | length')
		[[ $acnt -le 0 ]] && break
		echo $json_string | jq "$alertjq"
	done
}

cluster_alerts_args()
{
    OPTS=`getopt -o f:hs:e: --long "stime: etime: clusterjq: type: filters: alertjq: help" -n 'parse-options' -- "$@"`
    eval set -- "$OPTS"
    while true; do
        case "$1" in
            --type)         alerttype="$2";                shift 2;;
            --clusterjq)    clusterjq="$2";                shift 2;;
            --alertjq)      alertjq="$2";                  shift 2;;
            --filters | -f) filters="$2";                  shift 2;;
			--stime | -s)   stime=$(date --date "$2" +%s); shift 2;;
			--etime | -e)   etime=$(date --date "$2" +%s); shift 2;;
            -h | --help )   cluster_alerts_help;            exit 2;;
            -- ) shift; break ;;
            * ) break ;;
        esac
    done
	[[ $etime -lt $stime ]] && echo "etime should be greater than stime" && exit 2
}

cluster_alerts_cmd()
{
	cluster_alerts_args "$@"
	ak_api "$CWPP_URL/cluster-onboarding/api/v1/get-onboarded-clusters?wsid=$TENANT_ID"
	final_json=$(echo $json_string | jq -r "$clusterjq")
	cidlist=""
	while read cline; do
		cid=${cline/ */}
		cname=${cline/* /}
		[[ "$cidlist" != "" ]] && cidlist="$cidlist,"
		cidlist="$cidlist\"$cid\""
	done < <(echo $final_json | jq -r '. | "\(.ID) \(.ClusterName)"')
	cluster_alerts_query
}

