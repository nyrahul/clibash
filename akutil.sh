#!/bin/bash

. ${ACCUKNOX_CFG:-~/.accuknox.cfg}

DIR=/tmp/$$
TMP=$DIR/$(basename $0)

LOGLEVEL=${LOGLEVEL:-1} #0=dbg, 1=info, 2=warn, 3=err
ak_dbg()
{
	[[ $LOGLEVEL -gt 0 ]] && return
	echo "$*"
}
ak_info()
{
	[[ $LOGLEVEL -gt 1 ]] && return
	echo "$*"
}
ak_warn()
{
	[[ $LOGLEVEL -gt 2 ]] && return
	echo "$*"
}
ak_err()
{
	[[ $LOGLEVEL -gt 3 ]] && return
	echo "$*"
}

ak_help()
{
	cat <<EOH
## Setting AccuKnox configuration
* Please note that AccuKnox configuration ('.accuknox.cfg') would be needed to run the cli. [ref](https://github.com/accuknox/tools/tree/main/api-samples#setting-accuknoxcfg)
* Use API_VERBOSE=2 <cmd> ... to dump the request response of all the AccuKnox API calls.
EOH
}

ak_api()
{
	apiverbosity=${API_VERBOSE:-0}
	[[ $apiverbosity -gt 0 ]] && echo "API: [$1]"
	unset apicmd
	unset json_string
	read -r -d '' apicmd << EOH
curl $CURLOPTS "$1" \
	  -H "authorization: Bearer $TOKEN" \
	  -H 'content-type: application/json' \
	  -H "x-tenant-id: $TENANT_ID"
EOH
	if [ "$data_raw" != "" ]; then
		apicmd="$apicmd --data-raw '$data_raw'"
	fi
	[[ $apiverbosity -gt 1 ]] && echo "$apicmd"
	json_string=`eval "$apicmd"`
	if ! jq -e . >/dev/null 2>&1 <<<"$json_string"; then
		echo "API call failed: [$json_string]"
		exit 1
	fi
	[[ $apiverbosity -gt 1 ]] && echo "$json_string"
	unset data_raw
}

ak_prereq()
{
	[[ "$DIR" != "" ]] && mkdir -p $DIR
	command -v jq >/dev/null 2>&1 || { echo >&2 "require 'jq' to be installed. Aborting."; exit 1; }
	ak_dbg "tenant-id: $TENANT_ID"
}

function ak_cleanup {
	[[ "$DIR" != "" ]] && rm -rf $DIR
}

trap ak_cleanup EXIT

ak_prereq
