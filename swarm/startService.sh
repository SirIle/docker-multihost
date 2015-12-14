#!/bin/bash
[ $# -ne 2 ] || [ $1 == "-h" ] && { echo "Usage: $0 [-h] <service-name> <image>"; exit 1; }

if [ $AWS_ACCESS_KEY_ID ]; then
  eval $(docker-machine env --swarm swarm-0-aws)
  CONSUL=swarm-0-aws-consul:8500
  REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' registry-aws):5000
else
  eval $(docker-machine env --swarm swarm-0)
  CONSUL=swarm-0-consul:8500
  REGISTRY=$(docker-machine ip registry):5000
fi

if ! docker inspect rest &> /dev/null; then
  printf "\e[33m*** \e[32mStarting HAProxy \e[33m***\e[0m\n"
  docker run -d -h rest -e constraint:type==front-end --name=rest -e SERVICE_NAME=rest --dns 172.17.0.1 -p 80:80 -p 1936:1936 --net overlay $REGISTRY/haproxy -consul=$CONSUL
fi
NAME=$REGISTRY/$(basename $2)
printf "\e[33m*** \e[32mStarting image $NAME with the name $1 \e[33m***\e[0m\n"
docker run -d -e SERVICE_NAME=$1 -e SERVICE_TAGS=rest --dns 172.17.0.1 --net overlay $NAME
if [ $? == 1 ]; then
  printf "\e[33m*** \e[32mImage not found, trying to pull and push to private registry \e[33m***\e[0m\n"
  scripts/pullService.sh $2
  docker run -d -e SERVICE_NAME=$1 -e SERVICE_TAGS=rest --dns 172.17.0.1 --net overlay $NAME
fi
printf "\e[33m*** \e[32mService available at \e[31mhttp://$(docker inspect --format='{{.Node.IP}}' rest)/$1 \e[33m***\e[0m\n"
