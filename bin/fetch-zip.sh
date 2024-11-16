#!/bin/bash

# This fetches the zipped plugin from w.org. The zip might not exist yet if the plugin uses release confirmation
# and the release hasn't been confirmed. This will retry until the zip is available or the timeout is reached.

PLUGIN=$1
VERSION=$2
TIMEOUT=${3:-60}

if [ -z "$PLUGIN" ] || [ -z "$VERSION" ]; then
	echo "Usage: $0 <plugin> <version> [timeout]"
	exit 1
fi

zipurl="https://downloads.wordpress.org/plugin/${PLUGIN}.${VERSION}.zip"
echo "Fetching plugin ZIP from $zipurl ..."
elapsed=0
sleep=20
per_minute=$((60 / $sleep))
max_retries=$(( $TIMEOUT * $per_minute ))

while [ $elapsed -lt $max_retries ]; do
	# Perform a HEAD request to check if the ZIP is available
	status_code=$(curl -s -o /dev/null -w "%{http_code}" -I "$zipurl")
	if [ "$status_code" -eq 200 ]; then
		curl -s -o "$PLUGIN.zip" "$zipurl"
		break
	else
		echo "Plugin ZIP not available yet (HTTP status $status_code), retrying in $sleep seconds..."
		sleep $sleep
		elapsed=$((elapsed + 1))
	fi
done

if [ $elapsed -ge $max_retries ]; then
	echo "Error: $TIMEOUT minute timeout reached. Plugin ZIP not available."
	exit 1
fi
