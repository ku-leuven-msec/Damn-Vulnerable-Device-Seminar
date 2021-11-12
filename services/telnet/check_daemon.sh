#!/bin/bash
service=telnet
cd `dirname $0`/$service
ps | grep $service | grep -v grep | grep -v "check" && echo "ok" > /dev/null || (echo "Starting $service service" | python3 server.py)