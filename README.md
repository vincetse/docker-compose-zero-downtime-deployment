# Docker Compose Zero-Downtime Deployment

This design pattern uses Jason Wilder's (@jwilder) [Nginx proxy for Docker](https://github.com/jwilder/nginx-proxy) together with [Docker Compose](https://www.docker.com/products/docker-compose) to achieve an almost zero-downtime deployment process for Docker containers.

## Overview

Jason Wilder's blog post, [Automated Nginx Reverse Proxy for Docker]](http://jasonwilder.com/blog/2014/03/25/automated-nginx-reverse-proxy-for-docker/), describes how to use Nginx as a reverse proxy for Docker containers.  I initially took the naive approach of running one application container behind the reverse proxy, but realized I had a 10-second downtime each time I restarted the application container during upgrades, so I tried various configurations to try to achieve zero-downtime deployments and upgrades, and this is the closest I have gotten.  Please get in touch or send a pull request if you can do better.

## Prerequisites

1. Docker 1.10.3
1. Docker Compose 1.6.2

## Running

I have included Nginx proxy as part of my configuration for your convenience.  In a production setup, you may only need to run one instance of the Nginx proxy per host.  The following are the steps to trying out the configuration in this repo.

```
# Start Nginx proxy.  You really only need to do this once and leave it running.
docker-compose up -d proxy

# Start the application.
./deploy-and-restart.sh
```

## Details

The `deploy-and-restart.sh` script will build the application container, and start two derived instances of the application with edifferent names--`service_a` and `service_b`.  Both are the same image, but called different names so that start and stop them serparately with Docker Compose.

The following is the `deploy-and-restart.sh` script that does to achieve close to zero-downtime deployment.

1. Builds (or pull) the latest version of the Docker images.
1. If necesary, stop `service_a` before recreating and starting the container.
1. Pause for a few seconds in case the `service_a` takes a few seconds to start.
1. If necesary, stop `service_b` before recreating and starting the container.

```
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
```

The caveat here is that the application container might be put in service by the Nginx proxy before the application initializes completely.  I can't find a way around it without adding a healthcheck to the application and Nginx, but decided not to do it since this setup suffices for my needs.  I ran `curl` in a loop to test the setup, and no downtime was observed in my rudimentary test iwth a `bash` `while` loop.

```
# A bash loop running while the deployment happened.
while :;
    do curl localhost:8000;
    sleep 1;
done
```

The following is the `docker-compose.yml` file showing how the derived services are set up.

```
proxy:
  image: jwilder/nginx-proxy:0.2.0
  restart: always
  ports:
    - "8000:80"
  volumes:
    - "/var/run/docker.sock:/tmp/docker.sock:ro"

app:
  build: service
  restart: always
  ports:
    - "3000"
  environment:
    - VIRTUAL_HOST=localhost
    - VIRTUAL_PORT=3000

service_a:
  extends:
    service: app

service_b:
  extends:
    service: app
```

This setup suffices for me, but I would love to hear from you if you have a better setup.

## References

1. [@jwilder: Automated Nginx Reverse Proxy for Docker](http://jasonwilder.com/blog/2014/03/25/automated-nginx-reverse-proxy-for-docker/)
1. [Docker Compose: Extending services and Compose files](https://docs.docker.com/compose/extends/)
