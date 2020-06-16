# Docker Compose Zero-Downtime Deployment

This design pattern uses Jason Wilder's ([@jwilder](https://github.com/jwilder)) [Nginx proxy for Docker](https://github.com/jwilder/nginx-proxy) together with [Docker Compose](https://www.docker.com/products/docker-compose) to achieve an almost zero-downtime deployment process for Docker containers.

## Overview

Jason Wilder's blog post, [Automated Nginx Reverse Proxy for Docker]](http://jasonwilder.com/blog/2014/03/25/automated-nginx-reverse-proxy-for-docker/), describes how to use Nginx as a reverse proxy for Docker containers.  I initially took the naive approach of running one application container behind the reverse proxy, but realized I had a 10-second downtime each time I restarted the application container during upgrades, so I tried various configurations to try to achieve zero-downtime deployments and upgrades, and this is the closest I have gotten.  Please get in touch or send a pull request if you can do better.


## Prerequisites

1. Docker Engine 18.06.0+
1. Docker Compose 1.22.0+


## Demo Scripts

The [`docker-compose.yml`](docker-compose.yml) file configures that the demo scripts will use.  Here is a description of each of the services in the `docker-compose.yml` file.

| Service | Description |
|---------|-------------|
| `proxy` | The reverse proxy that uses Jason Wilder's [Nginx proxy for Docker](https://github.com/jwilder/nginx-proxy) image.  It monitors what back-end services are up, and registers them as Nginx [upstreams](https://stackoverflow.com/questions/5877929/what-does-upstream-mean-in-nginx). |
| `service_a` | One of the services behind the reverse proxy.  Emulates on version of a service. |
| `service_b` | Emulates another version of a service behind the reverse proxy. |
| `ab` | [Apache ab](https://httpd.apache.org/docs/2.4/programs/ab.html) emulating a continuous stream of requests to the reverse proxy. |


### `demo-all-backend-services-down.sh`

This is the base case where only `proxy` is up, but all the back-end services are down.  When `ab` runs, it will only be getting a bunch of HTTP 5xx responses, and on exit, will report that **Failed requests** is 0 (since the proxy was up), but **Non-2xx responses** is equal to the number of **Complete requests**, which means every single request did get any response from a back-end service since they were all down.  Here's a sample output on my laptop.

```
ab_1         | This is ApacheBench, Version 2.3 <$Revision: 1874286 $>
ab_1         | Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
ab_1         | Licensed to The Apache Software Foundation, http://www.apache.org/
ab_1         |
ab_1         | Benchmarking proxy (be patient)
ab_1         | Finished 158534 requests
ab_1         |
ab_1         |
ab_1         | Server Software:        nginx/1.9.12
ab_1         | Server Hostname:        proxy
ab_1         | Server Port:            80
ab_1         |
ab_1         | Document Path:          /
ab_1         | Document Length:        213 bytes
ab_1         |
ab_1         | Concurrency Level:      1
ab_1         | Time taken for tests:   120.000 seconds
ab_1         | Complete requests:      158534
ab_1         | Failed requests:        0
ab_1         | Non-2xx responses:      158534
ab_1         | Total transferred:      61035590 bytes
ab_1         | HTML transferred:       33767742 bytes
ab_1         | Requests per second:    1321.12 [#/sec] (mean)
ab_1         | Time per request:       0.757 [ms] (mean)
ab_1         | Time per request:       0.757 [ms] (mean, across all concurrent requests)
ab_1         | Transfer rate:          496.71 [Kbytes/sec] received
ab_1         |
ab_1         | Connection Times (ms)
ab_1         |               min  mean[+/-sd] median   max
ab_1         | Connect:        0    0   0.1      0       8
ab_1         | Processing:     0    0   0.2      0       8
ab_1         | Waiting:        0    0   0.2      0       8
ab_1         | Total:          0    1   0.2      1       9
ab_1         |
ab_1         | Percentage of the requests served within a certain time (ms)
ab_1         |   50%      1
ab_1         |   66%      1
ab_1         |   75%      1
ab_1         |   80%      1
ab_1         |   90%      1
ab_1         |   95%      1
ab_1         |   98%      1
ab_1         |   99%      1
ab_1         |  100%      9 (longest request)
```

### `demo-some-downtime-cutover.sh`

This script demonstrates a naive roll-out where `service_a` is taken down before starting `service_b`.  Naturally, there is a short period of unavailability since both back-end services were down.  In this example, `ab` will report that there were non-zero **Non-2xx responses** responses which was a small percentage of the number of **Complete requests** that hit the `proxy` when the back-end services were both down.

Here's the output from a run.

```
ab_1         | This is ApacheBench, Version 2.3 <$Revision: 1874286 $>
ab_1         | Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
ab_1         | Licensed to The Apache Software Foundation, http://www.apache.org/
ab_1         |
ab_1         | Benchmarking proxy (be patient)
ab_1         | Finished 56784 requests
ab_1         |
ab_1         |
ab_1         | Server Software:        nginx/1.9.12
ab_1         | Server Hostname:        proxy
ab_1         | Server Port:            80
ab_1         |
ab_1         | Document Path:          /
ab_1         | Document Length:        29 bytes
ab_1         |
ab_1         | Concurrency Level:      1
ab_1         | Time taken for tests:   120.000 seconds
ab_1         | Complete requests:      56784
ab_1         | Failed requests:        767
ab_1         |    (Connect: 0, Receive: 0, Length: 767, Exceptions: 0)
ab_1         | Non-2xx responses:      767
ab_1         | Total transferred:      12853100 bytes
ab_1         | HTML transferred:       1757184 bytes
ab_1         | Requests per second:    473.20 [#/sec] (mean)
ab_1         | Time per request:       2.113 [ms] (mean)
ab_1         | Time per request:       2.113 [ms] (mean, across all concurrent requests)
ab_1         | Transfer rate:          104.60 [Kbytes/sec] received
ab_1         |
ab_1         | Connection Times (ms)
ab_1         |               min  mean[+/-sd] median   max
ab_1         | Connect:        0    0   0.2      0       5
ab_1         | Processing:     0    2 133.6      1   31829
ab_1         | Waiting:        0    2 133.6      1   31829
ab_1         | Total:          0    2 133.6      1   31829
ab_1         |
ab_1         | Percentage of the requests served within a certain time (ms)
ab_1         |   50%      1
ab_1         |   66%      1
ab_1         |   75%      2
ab_1         |   80%      2
ab_1         |   90%      2
ab_1         |   95%      2
ab_1         |   98%      3
ab_1         |   99%      3
ab_1         |  100%  31829 (longest request)
```

### `demo-zero-downtime-deployment.sh`

This script starts the `proxy` with `service_a`, and after requests start coming from `ab`, `service_b` is brought up in preparation to stand in for `service_a`.  `Service_a` is hard-killed shortly after `service_b` comes up, and giving us a zero downtime deployment.  You will see that `ab` does not emit a line about **Non-2xx responses**, which means that all requests completed successfully.

Here is my run.

```
ab_1         | This is ApacheBench, Version 2.3 <$Revision: 1874286 $>
ab_1         | Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
ab_1         | Licensed to The Apache Software Foundation, http://www.apache.org/
ab_1         |
ab_1         | Benchmarking proxy (be patient)
ab_1         | Finished 56784 requests
ab_1         |
ab_1         |
ab_1         | Server Software:        nginx/1.9.12
ab_1         | Server Hostname:        proxy
ab_1         | Server Port:            80
ab_1         |
ab_1         | Document Path:          /
ab_1         | Document Length:        29 bytes
ab_1         |
ab_1         | Concurrency Level:      1
ab_1         | Time taken for tests:   120.000 seconds
ab_1         | Complete requests:      56784
ab_1         | Failed requests:        767
ab_1         |    (Connect: 0, Receive: 0, Length: 767, Exceptions: 0)
ab_1         | Non-2xx responses:      767
ab_1         | Total transferred:      12853100 bytes
ab_1         | HTML transferred:       1757184 bytes
ab_1         | Requests per second:    473.20 [#/sec] (mean)
ab_1         | Time per request:       2.113 [ms] (mean)
ab_1         | Time per request:       2.113 [ms] (mean, across all concurrent requests)
ab_1         | Transfer rate:          104.60 [Kbytes/sec] received
ab_1         |
ab_1         | Connection Times (ms)
ab_1         |               min  mean[+/-sd] median   max
ab_1         | Connect:        0    0   0.2      0       5
ab_1         | Processing:     0    2 133.6      1   31829
ab_1         | Waiting:        0    2 133.6      1   31829
ab_1         | Total:          0    2 133.6      1   31829
ab_1         |
ab_1         | Percentage of the requests served within a certain time (ms)
ab_1         |   50%      1
ab_1         |   66%      1
ab_1         |   75%      2
ab_1         |   80%      2
ab_1         |   90%      2
ab_1         |   95%      2
ab_1         |   98%      3
ab_1         |   99%      3
ab_1         |  100%  31829 (longest request)
```

## Summary

This setup sufficed for me in 2016, and it will still suffice for simple setups.  There are many options out there in 2020, so I would encourage you to explore.  I would love to hear from you if you have a better setup.


## References

1. [@jwilder: Automated Nginx Reverse Proxy for Docker](http://jasonwilder.com/blog/2014/03/25/automated-nginx-reverse-proxy-for-docker/)
1. [Don’t Repeat Yourself with Anchors, Aliases and Extensions in Docker Compose Files](https://medium.com/@kinghuang/docker-compose-anchors-aliases-extensions-a1e4105d70bd)
