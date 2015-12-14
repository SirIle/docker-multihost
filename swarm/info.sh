#!/bin/bash
if [ $AWS_ACCESS_KEY_ID ]; then
  REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' registry-aws):5000
  PROMETHEUS=http://$(docker-machine ip infra-aws):9090
  KIBANA=http://$(docker-machine ip infra-aws):5601
  eval $(docker-machine env --swarm swarm-0-aws)
else
  REGISTRY=$(docker-machine ip registry):5000
  PROMETHEUS=http://$(docker-machine ip infra):9090
  KIBANA=http://$(docker-machine ip infra):5601
  eval $(docker-machine env --swarm swarm-0)
fi
printf "\e[33m*** \e[32mKibana is available at \e[31m$KIBANA \e[33m***\e[0m\n"
printf "\e[33m*** \e[32mPrometheus is available at \e[31m$PROMETHEUS \e[33m***\e[0m\n"
printf "\e[33m*** \e[32mRegistry is available at \e[31m$REGISTRY \e[33m***\e[0m\n"
