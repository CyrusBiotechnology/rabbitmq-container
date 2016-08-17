#!/bin/bash

set -x
# Try to extract the hostname, first from RABBITMQ_NODENAME, then NODENAME
_NAME=`echo "$RABBITMQ_NODENAME" | awk -F '@' '{print $2}'`
[ -n "$_NAME" ] || NAME=`echo "$NODENAME" | awk -F '@' '{print $2}'`

if [ -n "$_NAME" ]; then
    # NAME is not empty. Is it in /etc/hosts?
    if [ -z "$(grep $_NAME /etc/hosts)" ]; then
        echo "127.0.0.1 $_NAME" >> /etc/hosts
    fi
fi

if [ "$1" == "rabbitmq-server" ]; then
  set +x
  exec /docker-entrypoint.sh "${@:1}"
else
  set +x
  exec "$@"
fi
