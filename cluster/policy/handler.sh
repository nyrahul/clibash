clusterjq='.[]'
policyjq='.'
polout="policydump"
operation="list"

cluster_policy_help()
{
	cat <<EOH
### [cluster policy] command
* --operation [list | dump]: Dump the policies in --dumpdir folder or list the policies
* --dumpdir | -d: Policy dump directory
* --clusterjq: jq filter to be used on cluster list output (default: '$clusterjq')
* --policyjq: jq filter to be used on policy list output (default: '$policyjq')

Examples:

1. knoxcli cluster policy --clusterjq '.[] | select(.ClusterName|test("gke"))' --policyjq '.list_of_policies[] | select(.name|test("crypto"))' <br>
	... get all the policies have 'crypto' in their name for all the clusters having 'gke' in their name

2. knoxcli cluster policy --clusterjq '.[] | select(.ClusterName|test("gke"))' --policyjq '.list_of_policies[] | select(.namespace_name // "notpresent"|test("agents"))' <br>
	... get all the policies in namespace agents ... if no namespace is present then "notpresent" is substituted.
EOH
}

cluster_policy_dump_policy_file()
{
	ak_api "$CWPP_URL/policymanagement/v2/policy/$1"
	echo "$json_string" | jq -r .yaml > $polpath
	[[ $? -ne 0 ]] && echo "could not get policy with ID=[$1]" && return
}

cluster_policy_get_policy_list()
{
	polperpage=10
	for((pgprev=0;;pgprev+=$polperpage)); do
		pgnext=$(($pgprev + $polperpage))
		echo "fetching policies $pgprev to $pgnext ..."
		data_raw="{\"workspace_id\":$TENANT_ID,\"workload\":\"k8s\",\"page_previous\":$pgprev,\"page_next\":$pgnext,\"filter\":{\"cluster_id\":[$1],\"namespace_id\":[],\"workload_id\":[],\"kind\":[],\"node_id\":[],\"pod_id\":[],\"type\":[],\"status\":[],\"tags\":[],\"name\":{\"regex\":[]},\"tldr\":{\"regex\":[]}}}"
		ak_api "$CWPP_URL/policymanagement/v2/list-policy"
		pcnt=$(echo "$json_string" | jq '.list_of_policies | length')
		[[ $pcnt -eq 0 ]] && echo "finished" && break
		final_json=$(echo "$json_string" | jq -r "$policyjq")
		[[ "$final_json" == "" ]] && continue
		while read pline; do
			arr=($pline)
			if [ "$operation" == "dump" ]; then
				poldir=$cpath/${arr[2]}
				mkdir -p $poldir 2>/dev/null
				polpath=$poldir/${arr[1]}.yaml
				echo $polpath
			else
				polpath=/dev/stdout
			fi
			cluster_policy_dump_policy_file ${arr[0]}
		done < <(echo $final_json | jq -r '. | "\(.policy_id) \(.name) \(.namespace_name)"')
	done
}

cluster_policy_cmd()
{
    # Remember to specify : in cases where argument is nessary both in short and long options
    OPTS=`getopt -o d:h --long "operation: policyjq: dumpdir: clusterjq: help" -n 'parse-options' -- "$@"`
    eval set -- "$OPTS"
    while true; do
        case "$1" in
            --operation)    operation="$2";                shift 2;;
            --clusterjq)    clusterjq="$2";                shift 2;;
            --policyjq)     policyjq="$2";                 shift 2;;
            -d | --dumpdir) polout="$2"; operation="dump"; shift 2;;
            -h | --help )  cluster_policy_help; return;    shift 1;;
            -- ) shift; break ;;
            * ) break ;;
        esac
    done
	[[ "$operation" != "list" ]] && [[ "$operation" != "dump" ]] && echo "invalid operation [$operation]!" && return
	ak_api "$CWPP_URL/cluster-onboarding/api/v1/get-onboarded-clusters?wsid=$TENANT_ID"
	filter_json=$(echo $json_string | jq -r "$clusterjq")
	while read cline; do
		cid=${cline/ */}
		cname=${cline/* /}
		if [ "$operation" == "dump" ]; then
			cpath=$polout/$cname
			mkdir $cpath 2>/dev/null
		fi
		echo "fetching policies for cluster [$cname] ..."
		cluster_policy_get_policy_list $cid
	done < <(echo "$filter_json" | jq -r '. | "\(.ID) \(.ClusterName)"')
}

