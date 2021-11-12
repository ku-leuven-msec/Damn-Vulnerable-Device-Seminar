#!/bin/bash
service=coap
cd `dirname $0`/coap
ps | grep $service | grep -v grep | grep -v "check" && echo "ok" > /dev/null || (echo "Starting $service service" | python3 server.py)