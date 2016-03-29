#!/bin/bash -eux

# Build the new image, or pull it from a repo.
# Touch server.sh to create new timestamp.
touch service/server.sh
docker-compose build --no-cache app service_a service_b

# Shut down Service A first, and restart with new image
docker-compose stop service_a
docker-compose up -d --force-recreate service_a

# Wait a little in case the service takes a bit to start
sleep 5

# Now shut down and restart Service B with new image.
docker-compose stop service_b
docker-compose up -d --force-recreate service_b
