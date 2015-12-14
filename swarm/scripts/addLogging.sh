#!/bin/bash

if [ $AWS_ACCESS_KEY_ID ]; then
  REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' registry-aws):5000
  ELASTICSEARCH=http://$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' infra-aws):9200
  LOGSTASH=syslog://$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' infra-aws):5000
  SWARM_MEMBERS=$(docker-machine ls | grep 'swarm-.-aws' | awk '{print $1}' | xargs)
  KIBANA=http://$(docker-machine ip infra-aws):5601
  eval $(docker-machine env infra-aws)
else
  REGISTRY=$(docker-machine ip registry):5000
  ELASTICSEARCH=http://$(docker-machine ip infra):9200
  LOGSTASH=syslog://$(docker-machine ip infra):5000
  SWARM_MEMBERS=$(docker-machine ls | grep 'swarm-.[ ]' | awk '{print $1}' | xargs)
  KIBANA=http://$(docker-machine ip infra):5601
  eval $(docker-machine env infra)
fi

if ! docker inspect logbox &> /dev/null; then
  printf "\e[33m*** \e[32mStarting LogBox \e[33m***\e[0m\n"
  docker run -d --name logbox -h logbox -p 5000:5000/udp -p 9200:9200 $REGISTRY/minilogbox
  docker run -d -p 5601:5601 -h kibanabox --name kibanabox $REGISTRY/kibanabox $ELASTICSEARCH
else
  printf "\e[33m*** \e[32mLogBox already running\e[33m***\e[0m\n"
fi

printf "\e[33m*** \e[32mServers in the swarm: $SWARM_MEMBERS \e[33m***\e[0m\n"
for server in $SWARM_MEMBERS; do
  if ! docker $(docker-machine config $server) inspect logspout &> /dev/null; then
    printf "\e[33m*** \e[32mStarting logspout on $server \e[33m***\e[0m\n"
    docker $(docker-machine config $server) run -d --name logspout -h logspout -p 8100:8000 -v /var/run/docker.sock:/tmp/docker.sock $REGISTRY/logspout $LOGSTASH
  else
    printf "\e[33m*** \e[32mLogspout already running on $server \e[33m***\e[0m\n"
  fi
done
printf "\e[33m*** \e[32mLogging system started, Kibana is available at \e[31m$KIBANA \e[33m***\e[0m\n"
