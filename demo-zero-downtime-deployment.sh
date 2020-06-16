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
wait_a_few_seconds 5

log "Run ab in the background against Proxy and Service A"
docker-compose up -d ab
wait_a_few_seconds 5

log "Start Service B to prepare for cutover"
docker-compose up -d service_b
wait_a_few_seconds 5

log "Stopping Service A to let Service B take over completely"
docker-compose stop service_a
wait_a_few_seconds 5

log "Giving ab some time to finish"
wait_a_few_seconds 120
docker-compose logs ab
log "There should have been no non-2xx responses, i.e. the line is missing"
