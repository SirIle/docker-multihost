#!/bin/bash
# Creates the infra node
source docker-functions.sh

# Create infrastructure node
checkNode infra
if [[ $? -ne 0 ]] ; then
  echo "** Creating infra node **"
  docker-machine create -d virtualbox infra
else
  echo "** Infra node already exists, skipping **"
fi
# Start Consul
checkService infra consul
if [ $? -eq 0 ]; then
  echo "** Starting consul server on infra **"
  docker $(docker-machine config infra) run -d -p 172.17.42.1:53:53 -p 172.17.42.1:53:53/udp -p 8300:8300 -p 8301:8301 -p 8301:8301/udp -p 8302:8302 -p 8302:8302/udp -p 8400:8400 -p 8500:8500 --name consul progrium/consul -server -bootstrap-expect 1 -advertise $(docker-machine ip infra)
else
  echo "** Consul already running, skipping **"
fi
