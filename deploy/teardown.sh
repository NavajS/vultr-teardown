#!/usr/bin/env bash
set -euo pipefail

: "${VULTR_API_KEY:?Set VULTR_API_KEY}"
instanceLabel="${LABEL:-iris-server}"
dryRun="${DRY_RUN:-0}"
apiBase="${VULTR_API:-https://api.vultr.com/v2}"

listMatchingIds() {
	curl -fsS -H "Authorization: Bearer ${VULTR_API_KEY}" "${apiBase}/instances?per_page=100" \
		| jq -r --arg label "${instanceLabel}" '.instances[] | select(.label == $label) | .id'
}

matchingIds="$(listMatchingIds)"
if [ -z "${matchingIds}" ]; then
	echo "No instances labeled ${instanceLabel}. Nothing to destroy."
	exit 0
fi

for instanceId in ${matchingIds}; do
	if [ "${dryRun}" = "1" ]; then
		echo "Would destroy ${instanceId}"
	else
		echo "Destroying ${instanceId}"
		curl -fsS -X DELETE -H "Authorization: Bearer ${VULTR_API_KEY}" "${apiBase}/instances/${instanceId}"
	fi
done

if [ "${dryRun}" = "1" ]; then
	exit 0
fi

sleep "${VERIFY_DELAY_S:-20}"
remainingIds="$(listMatchingIds)"
if [ -n "${remainingIds}" ]; then
	echo "Still present after delete: ${remainingIds}"
	exit 1
fi
echo "All instances labeled ${instanceLabel} are destroyed."
