#!/bin/bash
service=telnet
P=`dirname $0`
ps | grep "$service/server.py" | grep -v grep | grep -v "check"
if [ $? -eq 0 ]; then
  echo "Already Running" >> "$service.log"
else
  echo "Starting $service service" >> "$service.log"
  python3 "$P/server.py" >> "$service.log"
fi