#!/bin/bash
[ $# -ne 2 ] || [ $1 == "-h" ] && { echo "Usage: $0 [-h] <service-name> <image>"; exit 1; }
# Point to the swarm master
eval $(docker-machine env --swarm swarm-master)
# Check that at least 1 instance of rest-HAProxy is running
HAPROXY=$(docker ps | awk '{print $1,$2}' | grep haproxy | wc -l)
if [[ $HAPROXY -lt 1 ]]; then
  echo "** At least one instance of HAProxy needs to be running, starting **"
  docker run -d -h rest --name=rest -e SERVICE_NAME=rest -p 80:80 -p 1936:1936 sirile/haproxy -consul=$(docker-machine ip infra):8500
fi
echo "** Starting image $2 with the name $1 **"
docker run -d -e SERVICE_NAME=$1 -e SERVICE_TAGS=rest -p :80 $2
REST_ADDR=$(docker inspect $(docker ps -f name=rest -q) | grep IP\" | cut -d '"' -f 4)
echo "** Service available at http://$REST_ADDR/$1 **"
