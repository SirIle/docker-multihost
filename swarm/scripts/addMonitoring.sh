#!/bin/bash
if [ $AWS_ACCESS_KEY_ID ]; then
  REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' registry-aws):5000
  SWARM_MEMBERS=$(docker-machine ls | grep 'swarm-.-aws' | awk '{print $1}' | xargs)
  SERVERS="['$(docker-machine ls | grep 'swarm-.-aws' | awk '{print $1}' | xargs -I{} docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' {} | xargs | sed -e "s/ /:8080','/g"):8080']"
  PROMETHEUS=http://$(docker-machine ip infra-aws):9090
  eval $(docker-machine env infra-aws)
else
  REGISTRY=$(docker-machine ip registry):5000
  SWARM_MEMBERS=$(docker-machine ls | grep 'swarm-.[ ]' | awk '{print $1}' | xargs)
  SERVERS="['$(docker-machine ip $(docker-machine ls | grep 'swarm-.[ ]' | awk '{print $1}' ) | xargs | sed -e "s/ /:8080','/g"):8080']"
  PROMETHEUS=http://$(docker-machine ip infra):9090
  eval $(docker-machine env infra)
fi

printf "\e[33m*** \e[32mServers in the swarm: $SWARM_MEMBERS \e[33m***\e[0m\n"
for server in $SWARM_MEMBERS; do
  if ! docker $(docker-machine config $server) inspect cadvisor &> /dev/null; then
    printf "\e[33m*** \e[32mStarting cadvisor on $server \e[33m***\e[0m\n"
    docker $(docker-machine config $server)  run --name cadvisor --volume=/:/rootfs:ro --volume=/var/run:/var/run:rw --volume=/sys:/sys:ro --volume=/var/lib/docker/:/var/lib/docker:ro --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro --publish=8080:8080 --detach=true --name=cadvisor $REGISTRY/cadvisor
  else
    printf "\e[33m*** \e[32mcadvisor already running on $server \e[33m***\e[0m\n"
  fi
done

# Sed the servers to the config file
sed -i '' 's/- targets.*/- targets: '$SERVERS'/g' $(dirname ${BASH_SOURCE[0]})/prometheus.yml

if ! docker inspect prometheus &> /dev/null; then
  printf "\e[33m*** \e[32mStarting Prometheus \e[33m***\e[0m\n"
  # With alert manager it would be like:
  # docker run -d -p 9093:9093 -v $PWD/alertmanager.conf:/alertmanager.conf prom/alertmanager -config.file=/alertmanager.conf
  # docker $(docker-machine config infra) run -d -p 9090:9090 --name prometheus -v $PWD/prometheus.yml:/etc/prometheus/prometheus.yml -v $PWD/alert.rules:/etc/prometheus/alert.rules prom/prometheus -config.file=/etc/prometheus/prometheus.yml -alertmanager.url=http://$(docker-machine ip infra):9093
  if [ $AWS_ACCESS_KEY_ID ]; then
    # Copy the configuration file over
    docker-machine scp $(dirname ${BASH_SOURCE[0]})/prometheus.yml infra-aws:/tmp/prometheus.yml
    docker run -d -p 9090:9090 --name prometheus -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml $REGISTRY/prometheus
  else
    docker run -d -p 9090:9090 --name prometheus -v $(cd $(dirname ${BASH_SOURCE[0]}); pwd)/prometheus.yml:/etc/prometheus/prometheus.yml $REGISTRY/prometheus
  fi
else
  printf "\e[33m*** \e[32mPrometheus already running on infra, sending sighup to reload config \e[33m***\e[0m\n"
  if [ $AWS_ACCESS_KEY_ID ]; then
    docker-machine scp $(dirname ${BASH_SOURCE[0]})/prometheus.yml infra-aws:/tmp/prometheus.yml
  fi
  docker exec prometheus kill -SIGHUP 1
fi
printf "\e[33m*** \e[32mPrometheus UI can be found at \e[31m$PROMETHEUS \e[33m***\e[0m\n"
