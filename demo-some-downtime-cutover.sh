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
docker-compose build service_a service_b

log "Starting Proxy and Service A"
docker-compose up -d proxy service_a
wait_a_few_seconds 10

log "Run ab in the background against Proxy and Service A"
docker-compose up -d ab
wait_a_few_seconds 10

log "Stopping Service A to create some downtime"
docker-compose kill -s SIGKILL service_a
wait_a_few_seconds 20

log "Start Service B to pick up"
docker-compose up -d service_b
wait_a_few_seconds 5

log "Giving ab some time to finish"
wait_a_few_seconds 120
docker-compose logs ab
log "There should have been some non-2xx responses, i.e. there was some downtime"
