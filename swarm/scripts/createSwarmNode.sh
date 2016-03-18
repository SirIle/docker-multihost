#!/bin/bash

# Number zero is master, rest are normal swarm-nodes
[ $# -lt 1 ] || [ $1 == "-h" ] && { echo "Usage: $0 [-h] <id, 0 for master> [label]"; exit 1; }

[ $2 ] && OPTIONS="--engine-label=\"type=$2\""

if [ $AWS_ACCESS_KEY_ID ]; then
  CONSUL=$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' infra-aws)
  REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' registry-aws):5000
  if [ $1 -eq 0 ]; then
    NAME='swarm-0-aws'
    if ! docker-machine inspect $NAME &> /dev/null; then
      printf "\e[33m*** \e[32mCreating swarm master with the name '$NAME' to AWS \e[33m***\e[0m\n"
      docker-machine create -d amazonec2 --swarm --swarm-master --swarm-discovery consul://$CONSUL:8500 --swarm-image $REGISTRY/swarm --engine-opt="cluster-store=consul://$CONSUL:8500" --amazonec2-ami=ami-fe001292 --engine-opt="cluster-advertise=eth0:2376" $OPTIONS --swarm-image $REGISTRY/swarm --engine-insecure-registry=$REGISTRY $NAME
      printf "\e[33m*** \e[32mCreating network overlay \e[33m***\e[0m\n"
      docker $(docker-machine config $NAME) network create --driver overlay overlay
      printf "\e[33m*** \e[32mStarting master consul \e[33m***\e[0m\n"
      docker $(docker-machine config $NAME) run -d -p 172.17.0.1:53:53 -p 172.17.0.1:53:53/udp -p 8500:8500 --name $NAME-consul --net overlay $REGISTRY/consul -server -bootstrap-expect 1
    else
      printf "\e[33m*** \e[32mswarm-0-aws already running \e[33m***\e[0m\n"
      exit 1
    fi
  else
    NAME="swarm-$1-aws"
    # For some reason the join only works with an IP address, not with hostname
    OVERLAY_CONSUL=$(docker $(docker-machine config swarm-0-aws) inspect -f '{{(index .NetworkSettings.Networks "overlay").IPAddress}}' swarm-0-aws-consul)
    if ! docker-machine inspect $NAME &> /dev/null; then
      printf "\e[33m*** \e[32mCreating swarm node with the name '$NAME' to AWS, label: $2 \e[33m***\e[0m\n"
      docker-machine create --driver amazonec2 --swarm --swarm-discovery consul://$CONSUL:8500 --swarm-image $REGISTRY/swarm --engine-opt="cluster-store=consul://$CONSUL:8500" --amazonec2-ami=ami-fe001292 --engine-opt="cluster-advertise=eth0:2376" $OPTIONS --engine-insecure-registry=$REGISTRY $NAME
      printf "\e[33m*** \e[32mStarting slave consul \e[33m***\e[0m\n"
      docker $(docker-machine config $NAME) run -d -p 172.17.0.1:53:53 -p 172.17.0.1:53:53/udp -p 8500:8500 --name $NAME-consul --net overlay $REGISTRY/consul -join $OVERLAY_CONSUL
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
      docker-machine create --driver virtualbox --swarm --swarm-master  --swarm-discovery consul://$CONSUL:8500 --swarm-image $REGISTRY/swarm --engine-opt="cluster-store=consul://$CONSUL:8500" $OPTIONS --engine-opt="cluster-advertise=eth1:2376" --engine-insecure-registry=$REGISTRY $NAME
      printf "\e[33m*** \e[32mCreating network overlay \e[33m***\e[0m\n"
      docker $(docker-machine config $NAME) network create --driver overlay overlay
      printf "\e[33m*** \e[32mStarting master consul \e[33m***\e[0m\n"
      docker $(docker-machine config $NAME) run -d -p 172.17.0.1:53:53 -p 172.17.0.1:53:53/udp -p 8500:8500 --name $NAME-consul --net overlay $REGISTRY/consul -server -bootstrap-expect 1
    else
      printf "\e[33m*** \e[32mswarm-0 already running \e[33m***\e[0m\n"
      exit 1
    fi
  else
    NAME="swarm-$1"
    # For some reason the join only works with an IP address, not with hostname
    OVERLAY_CONSUL=$(docker $(docker-machine config swarm-0) inspect -f '{{(index .NetworkSettings.Networks "overlay").IPAddress}}' swarm-0-consul)
    if ! docker-machine inspect $NAME &> /dev/null; then
      printf "\e[33m*** \e[32mCreating swarm node with the name '$NAME' locally, label: $2 \e[33m***\e[0m\n"
      docker-machine create --driver virtualbox --swarm --swarm-discovery consul://$CONSUL:8500 --swarm-image $REGISTRY/swarm --engine-opt="cluster-store=consul://$CONSUL:8500" --engine-opt="cluster-advertise=eth1:2376" $OPTIONS --engine-insecure-registry=$REGISTRY $NAME
      printf "\e[33m*** \e[32mStarting slave consul \e[33m***\e[0m\n"
      docker $(docker-machine config $NAME) run -d -p 172.17.0.1:53:53 -p 172.17.0.1:53:53/udp -p 8500:8500 --name $NAME-consul --net overlay $REGISTRY/consul -join $OVERLAY_CONSUL
    else
      printf "\e[33m*** \e[32m$NAME already running \e[33m***\e[0m\n"
      exit 1
    fi
  fi
  NODE_IP=$(docker-machine ip $NAME)
fi
eval $(docker-machine env $NAME)
printf "\e[33m*** \e[32mStarting registrator \e[33m***\e[0m\n"
docker run -d -v //var/run/docker.sock:/tmp/docker.sock -h registrator --name $NAME-registrator --net overlay $REGISTRY/registrator -internal consul://$NAME-consul:8500
printf "\e[33m*** \e[32mStarted a new node with IP \e[31m$(docker-machine ip $NAME) \e[33m***\e[0m\n"
