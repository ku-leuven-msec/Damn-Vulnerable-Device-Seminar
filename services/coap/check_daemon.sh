#!/bin/bash
service=coap
cd `dirname $0`
ps | grep $service | grep -v grep | grep -v "check" && echo "ok" > /dev/null || (su client && (echo "Starting $service service" | python3 server.py >> "$service.log"))