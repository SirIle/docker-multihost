#!/bin/bash

# Check if a machine already exists and quit if it does
function checkExisting() {
  ( docker-machine ls | grep "^$1 " ) >> /dev/null
  if [[ $? -eq 0 ]] ; then
    echo "ERROR: $1 already exists"
    exit 1
  fi
}

# Number zero is master, rest are normal swarm-nodes
[ $# -ne 1 ] || [ $1 == "-h" ] && { echo "Usage: $0 [-h] <id, 0 for master>"; exit 1; }
# Check that infra machine exists
( docker-machine ls | grep "^infra " ) >> /dev/null
if [[ $? -ne 0 ]] ; then
  echo "ERROR: Infra node doesn't exist, please create it first"
  exit 1
fi

if [ $1 -eq 0 ]
then
  NAME='swarm-master'
  echo "** Creating swarm master with the name '$NAME' **"
  # Check that the machine doesn't already exist
  checkExisting $NAME
  docker-machine create -d virtualbox --swarm --swarm-master --swarm-discovery consul://$(docker-machine ip infra):8500 swarm-master
else
  ( docker-machine ls | grep "^swarm-master " ) >> /dev/null
  if [[ $? -ne 0 ]] ; then
    echo "ERROR: swarm-master doesn't exist, please create it first"
    exit 1
  fi
  NAME='swarm-app-'$1
  echo "** Creating swarm node with the name '$NAME' **"
  checkExisting $NAME
  docker-machine create -d virtualbox --swarm --swarm-discovery consul://$(docker-machine ip infra):8500 $NAME
fi
echo "** Starting consul and joining it to the infra node **"
docker $(docker-machine config $NAME) run -d -p 172.17.42.1:53:53 -p 172.17.42.1:53:53/udp -p 8301:8301 -p 8301:8301/udp -p 8500:8500 --name consul progrium/consul -join $(docker-machine ip infra) -advertise $(docker-machine ip $NAME)
echo "** Starting registrator ** "
docker $(docker-machine config $NAME) run -d -v /var/run/docker.sock:/tmp/docker.sock -h registrator --name registrator gliderlabs/registrator consul://$(docker-machine ip $NAME):8500
echo "** Started a new node with IP $(docker-machine ip $NAME) **"
