#!/bin/bash

# Number zero is master, rest are normal swarm-nodes
[ $# -ne 1 ] || [ $1 == "-h" ] && { echo "Usage: $0 [-h] <id, 0 for master>"; exit 1; }

if [ $AWS_ACCESS_KEY_ID ]; then
  CONSUL=$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' infra-aws)
  REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' registry-aws):5000
  if [ $1 -eq 0 ]; then
    NAME='swarm-0-aws'
    if ! docker-machine inspect $NAME &> /dev/null; then
      printf "\e[33m*** \e[32mCreating swarm master with the name '$NAME' to AWS \e[33m***\e[0m\n"
      docker-machine create --driver amazonec2 --swarm --swarm-master --swarm-discovery consul://$CONSUL:8500 --engine-insecure-registry=$REGISTRY $NAME
    else
      printf "\e[33m*** \e[32mswarm-0-aws already running \e[33m***\e[0m\n"
      exit 1
    fi
  else
    NAME="swarm-$1-aws"
    if ! docker-machine inspect $NAME &> /dev/null; then
      printf "\e[33m*** \e[32mCreating swarm node with the name '$NAME' to AWS \e[33m***\e[0m\n"
      docker-machine create --driver amazonec2 --swarm --swarm-discovery consul://$CONSUL:8500 --engine-insecure-registry=$REGISTRY $NAME
    else
      printf "\e[33m*** \e[32m$NAME already running \e[33m***\e[0m\n"
      exit 1
    fi
  fi
  NODE_IP=$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' $NAME)
else
  CONSUL=$(docker-machine ip infra)
  REGISTRY=$(docker-machine ip registry):5000
  if [ $1 -eq 0 ]; then
    NAME='swarm-0'
    if ! docker-machine inspect $NAME &> /dev/null; then
      printf "\e[33m*** \e[32mCreating swarm master with the name '$NAME' locally \e[33m***\e[0m\n"
      docker-machine create --driver virtualbox --swarm --swarm-master --swarm-discovery consul://$CONSUL:8500 --engine-insecure-registry=$REGISTRY $NAME
    else
      printf "\e[33m*** \e[32mswarm-0 already running \e[33m***\e[0m\n"
      exit 1
    fi
  else
    NAME="swarm-$1"
    if ! docker-machine inspect $NAME &> /dev/null; then
      printf "\e[33m*** \e[32mCreating swarm node with the name '$NAME' locally \e[33m***\e[0m\n"
      docker-machine create --driver virtualbox --swarm --swarm-discovery consul://$CONSUL:8500 --engine-insecure-registry=$REGISTRY $NAME
    else
      printf "\e[33m*** \e[32m$NAME already running \e[33m***\e[0m\n"
      exit 1
    fi
  fi
  NODE_IP=$(docker-machine ip $NAME)
fi
printf "\e[33m*** \e[32mStarting consul ($NODE_IP) and joining it to the infra node at $CONSUL \e[33m***\e[0m\n"
eval $(docker-machine env $NAME)
docker run -d -p 172.17.42.1:53:53 -p 172.17.42.1:53:53/udp -p 8301:8301 -p 8301:8301/udp -p 8500:8500 --name consul $REGISTRY/consul -join $CONSUL -advertise $NODE_IP
printf "\e[33m*** \e[32mStarting registrator \e[33m***\e[0m\n"
docker run -d -v /var/run/docker.sock:/tmp/docker.sock -h registrator --name registrator $REGISTRY/registrator -ip $NODE_IP consul://$NODE_IP:8500
printf "\e[33m*** \e[32mStarted a new node with IP \e[31m$(docker-machine ip $NAME) \e[33m***\e[0m\n"
