clusterjq='.[] | "id=\(.ID),name=\(.ClusterName),status=\(.Status)"'
nodejq='.result[].NodeName'
spec=".*"
show_nodes=0

cluster_list_help()
{
	cat <<EOH
cluster list [options]
     --spec | -s: [requires value] search filter for cluster names (regex based)
     --nodes | -n: lists nodes from the clusters
     --clusterjq: jq filter to be used on cluster list output (default: '$clusterjq')
                  Example, select clusternames starting with idt '.[] | select(.ClusterName|test("idt.")) | "id=\(.ID),name=\(.ClusterName),status=\(.Status)"'    
     --nodejq: jq filter to be used on node list output (default: '$nodejq')
EOH
	ak_help
}

cluster_list_get_node_list()
{
	echo "List of nodes in cluster [$cname]:"
	data_raw="{\"workspace_id\":$TENANT_ID,\"cluster_id\":[$cid],\"from_time\":[],\"to_time\":[]}"
	ak_api "$CWPP_URL/cm/api/v1/cluster-management/nodes-in-cluster"
	echo $json_string | jq -r "$nodejq"
}

cluster_list_cmd()
{
    # Remember to specify : in cases where argument is nessary both in short and long options
    OPTS=`getopt -o hns: --long "nodes spec: clusterjq: nodejq: help" -n 'parse-options' -- "$@"`
    eval set -- "$OPTS"
    while true; do
        case "$1" in
            -s | --spec )  spec="$2";                 shift 2;;
            -n | --nodes ) show_nodes=1;              shift 1;;
            --nodejq )     nodejq="$2"; show_nodes=1; shift 2;;
            --clusterjq)   clusterjq="$2";            shift 2;;
            -h | --help )  cluster_list_help; return; shift 1;;
            -- ) shift; break ;;
            * ) break ;;
        esac
    done
	ak_prereq
	echo "List of clusters:"
	ak_api "$CWPP_URL/cluster-onboarding/api/v1/get-onboarded-clusters?wsid=$TENANT_ID"
	echo $json_string | jq -r "$clusterjq"
	[[ $show_nodes -eq 0 ]] && return
	while read cline; do
		cid=${cline/ */}
		cname=${cline/* /}
		[[ ! $cname =~ $spec ]] && ak_dbg "ignoring cluster [$cname] ..." && continue
		cluster_list_get_node_list
	done < <(echo $json_string | jq -r '.[] | "\(.ID) \(.ClusterName)"')
}
