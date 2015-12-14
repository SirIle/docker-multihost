#!/bin/bash
# Remove monitoring by removing Prometheus from infra node and cAdvisor from everywhere
if [ $AWS_ACCESS_KEY_ID ]; then
  docker $(docker-machine config infra-aws) rm -f prometheus
  eval $(docker-machine env --swarm swarm-0-aws)

else
  docker $(docker-machine config infra) rm -f prometheus
  eval $(docker-machine env --swarm swarm-0)
fi
docker rm -f $(docker ps | awk '{print $1,$2}' | grep cadvisor | awk '{print $1}')
