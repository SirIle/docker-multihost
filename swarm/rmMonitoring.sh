#!/bin/bash
# Remove monitoring by removing Prometheus from infra node and cAdvisor from everywhere
eval $(docker-machine env --swarm swarm-master)
docker rm -f $(docker ps | awk '{print $1,$2}' | grep cadvisor | awk '{print $1}')
docker $(docker-machine config infra) rm -f prometheus
