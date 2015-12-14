#!/bin/bash
# Remove logging by removing LogBox and Kibana on infra and logspout on all nodes
if [ $AWS_ACCESS_KEY_ID ]; then
  docker $(docker-machine config infra-aws) rm -f logbox kibanabox
  eval $(docker-machine env --swarm swarm-0-aws)
else
  docker $(docker-machine config infra) rm -f logbox kibanabox
  eval $(docker-machine env --swarm swarm-0)
fi
docker rm -f $(docker ps | awk '{print $1,$2}' | grep logspout | awk '{print $1}')
