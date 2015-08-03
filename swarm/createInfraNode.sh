#!/bin/bash
# Creates the infra node
source docker-functions.sh

# Create infrastructure node
checkNode infra
if [[ $? -ne 0 ]] ; then
  # Check if Amazon keys are in the variables and if they are, create to AWS
  if [ $AWS_ACCESS_KEY_ID ]; then
    echo "** Creating infra node into AWS **"
    docker-machine -D create -d amazonec2 infra
  else
    echo "** Creating infra node locally **"
    docker-machine create -d virtualbox infra
  fi
else
  echo "** Infra node already exists, skipping **"
fi
# Start Consul
checkService infra consul
if [ $? -eq 0 ]; then
  echo "** Starting consul server on infra **"
  if [ $AWS_ACCESS_KEY_ID ]; then
    docker $(docker-machine config infra) run -d -p 172.17.42.1:53:53 -p 172.17.42.1:53:53/udp -p 8300:8300 -p 8301:8301 -p 8301:8301/udp -p 8302:8302 -p 8302:8302/udp -p 8400:8400 -p 8500:8500 --name consul progrium/consul -server -bootstrap-expect 1 -advertise $(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' infra)
  else
    docker $(docker-machine config infra) run -d -p 172.17.42.1:53:53 -p 172.17.42.1:53:53/udp -p 8300:8300 -p 8301:8301 -p 8301:8301/udp -p 8302:8302 -p 8302:8302/udp -p 8400:8400 -p 8500:8500 --name consul progrium/consul -server -bootstrap-expect 1 -advertise $(docker-machine ip infra)
  fi
else
  echo "** Consul already running, skipping **"
fi
