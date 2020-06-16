#!/bin/bash
set -eo pipefail

trap cleanup EXIT

function cleanup()
{
  docker-compose down
}

function log()
{
  echo "# $@"
}

function wait_a_few_seconds()
{
  local delay=$1
  sleep ${delay}
}

# Prepare all the images
docker-compose down
docker-compose pull proxy ab

log "Starting proxy without any backend services to emulate a 100% outage."
docker-compose up -d proxy
wait_a_few_seconds 5

log "Run ab, and you should expect to see 50000 Non-2xx requests"
docker-compose up ab
docker-compose down
