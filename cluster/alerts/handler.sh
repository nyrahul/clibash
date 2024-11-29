clusterjq='.[] | select(.ClusterName|test("idt")'
stimestr="2 days ago"
stime=$(date -d "$stimestr" +%s)
etime=$(date +%s)
alerttype="kubearmor"

cluster_alerts_help()
{
	cat <<EOH
### cluster alerts [options]
     --clusterjq [jq-spec]: jq filter to be used on cluster list output (default: '$clusterjq')
	 --stime [datetime]: start time in epoch format (default: '$stime', $stimestr)
	 --etime [datetime]: end time in epoch format (default: '$etime', now)
	 --type [alert-type]: alert-type (default: "$alerttype)

Examples:
1. knoxcli cluster list --clusterjq '.[] | select(.ClusterName|test("idt."))' --nodes
	... list all the clusters with idt substring in its names and list all the nodes in those clusters
2. knoxcli cluster list --clusterjq '.[] | select((.type == "vm") and (.Status == "Inactive")) | "id=\(.ID),name=\(.ClusterName),status=\(.Status)"'
	... list all the Inactive VM clusters and print their ID,name,status

EOH
}

cluster_alerts_query()
{
	for((pgid=100;;pgid++)); do
		data_raw="{\"Namespace\":[],\"FromTime\":$stime,\"ToTime\":$etime,\"PageId\":$pgid,\"PageSize\":20,\"Filters\":[],\"ClusterID\":[$cidlist],\"View\":\"List\",\"Type\":\"$alerttype\",\"WorkloadType\":[],\"WorkloadName\":[],\"WorkspaceID\":$TENANT_ID}"
		ak_api "$CWPP_URL/monitors/v1/alerts/events?orderby=desc"
		echo $json_string | jq '.response | length'
		exit
	done
}

cluster_alerts_args()
{
    OPTS=`getopt -o hs:e: --long "stime: etime: clusterjq: type: help" -n 'parse-options' -- "$@"`
    eval set -- "$OPTS"
    while true; do
        case "$1" in
            --type)        alerttype="$2";                shift 2;;
            --clusterjq)   clusterjq="$2";                shift 2;;
			--stime | -s)  stime=$(date --date "$2" +%s); shift 2;;
			--etime | -e)  etime=$(date --date "$2" +%s); shift 2;;
            -h | --help )  cluster_alerts_help; exit 2;;
            -- ) shift; break ;;
            * ) break ;;
        esac
    done
	[[ $etime -lt $stime ]] && echo "etime should be greater than stime" && exit 2
}

cluster_alerts_cmd()
{
	cluster_alerts_args "$@"
	echo "List of clusters:"
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

