#!/bin/sh

VERSION=$(stat -c %z $0)

while :; do
    echo "HTTP/1.0 200 OK
Connection: close


Hello, world! -${VERSION}
" | nc -l 0.0.0.0 -p 3000
done
