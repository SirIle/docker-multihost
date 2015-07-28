#!/bin/bash
# Remove logging by removing LogBox and Kibana on infra and logspout on all nodes
docker $(docker-machine config infra) rm -f logbox kibanabox
eval $(docker-machine env --swarm swarm-master)
docker rm -f $(docker ps | awk '{print $1,$2}' | grep logspout | awk '{print $1}')
