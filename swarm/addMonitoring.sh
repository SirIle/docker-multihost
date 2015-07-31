#!/bin/bash
# Add monitoring to the swarm: start Prometheus and cAdvisor on infra, add cAdvisor to other nodes
source docker-functions.sh

# Check that infra exists
checkNode infra
if [[ $? -ne 0 ]] ; then
  echo "ERROR: Machine infra doesn't exist, please create it first"
  exit 1
fi

# Loop through swarm servers and start cAdvisor as needed
SWARM_MEMBERS=$(docker-machine ls | grep swarm | awk '{print $1}' | xargs)
echo "** Servers in the swarm: $SWARM_MEMBERS **"
for server in $SWARM_MEMBERS; do
  checkService $server cadvisor
  if [ $? -eq 0 ]; then
    echo "** Starting cAdvisor on $server"
    docker $(docker-machine config $server) run --name cadvisor --volume=/:/rootfs:ro --volume=/var/run:/var/run:rw --volume=/sys:/sys:ro --volume=/var/lib/docker/:/var/lib/docker:ro --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro --publish=8080:8080 --detach=true --name=cadvisor google/cadvisor:latest
  else
    echo "** cAdvisor already running on $server"
  fi
done

if [ $AWS_ACCESS_KEY ]; then
  SERVERS="['$(docker-machine ls | grep swarm | awk '{print $1}' | xargs -I{} docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' {} | xargs | sed -e "s/ /:8080','/g"):8080']"
else
  SERVERS="['$(docker-machine ip $(docker-machine ls | grep swarm | awk '{print $1}' ) | xargs | sed -e "s/ /:8080','/g"):8080']"
fi

# Sed the servers to the config file
sed -i '' 's/- targets.*/- targets: '$SERVERS'/g' prometheus.yml

# Start Prometheus on infra
checkService infra prometheus
if [ $? -eq 0 ]; then
  echo "** Starting Prometheus on infra **"
  # With alert manager it would be like:
  # docker run -d -p 9093:9093 -v $PWD/alertmanager.conf:/alertmanager.conf prom/alertmanager -config.file=/alertmanager.conf
  # docker $(docker-machine config infra) run -d -p 9090:9090 --name prometheus -v $PWD/prometheus.yml:/etc/prometheus/prometheus.yml -v $PWD/alert.rules:/etc/prometheus/alert.rules prom/prometheus -config.file=/etc/prometheus/prometheus.yml -alertmanager.url=http://$(docker-machine ip infra):9093
  if [ $AWS_ACCESS_KEY ]; then
    # Copy the configuration file over
    docker-machine scp $PWD/prometheus.yml infra:/tmp/prometheus.yml
    docker $(docker-machine config infra) run -d -p 9090:9090 --name prometheus -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
  else
    docker $(docker-machine config infra) run -d -p 9090:9090 --name prometheus -v $PWD/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
  fi
else
  echo "** Prometheus already running on infra, sending sighup to reload config **"
  if [ $AWS_ACCESS_KEY ]; then
    docker-machine scp $PWD/prometheus.yml infra:/tmp/prometheus.yml
  fi
  docker $(docker-machine config infra) exec prometheus kill -SIGHUP 1
fi
echo "Prometheus ui can be found at http://$(docker-machine ip infra):9090"
