#!/usr/bin/env bash

set -e

host="$1"
shift
cmd="nginx"

until curl -XGET $host:9200; do
  >&2 echo "Elastic is unavailable - sleeping"
  sleep 1
done

sleep 30

>&2 echo "Elastic is up - executing command"

if curl -XGET http://$host:9200/nxapi/ | grep '\"status\":404'; then
  echo "Creating nxapi elasticsearch index"
  curl -XPUT http://$host:9200/nxapi -d @/usr/src/es-index.json
else
  echo "nxapi elasticsearch index exists"
fi

/opt/nxapi/nxtool.py --no-timeout --fifo=/var/log/nginx/error_pipe.log &

exec $cmd
