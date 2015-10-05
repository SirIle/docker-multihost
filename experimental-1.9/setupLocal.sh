#!/bin/bash
printf "\e[33m*** \e[32mFetching the experimental boot2docker image to cache \e[33m***\e[0m\n"
if [ ! -f $HOME/.docker/machine/cache/boot2docker-1.9.iso ]; then
  curl -L http://sirile.github.io/files/boot2docker-1.9.iso > $HOME/.docker/machine/cache/boot2docker-1.9.iso
fi
export VIRTUALBOX_BOOT2DOCKER_URL=file://$HOME/.docker/machine/cache/boot2docker-1.9.iso

printf "\e[33m*** \e[32mCreating infra server \e[33m***\e[0m\n"
docker-machine create --driver virtualbox --engine-insecure-registry $(docker-machine ip registry):5000 infra
docker $(docker-machine config infra) run -d -p 8500:8500 $(docker-machine ip registry):5000/consul -server -bootstrap-expect 1
export SWARM_TOKEN=$(docker $(docker-machine config infra) run --rm $(docker-machine ip registry):5000/swarm create)

printf "\e[33m*** \e[32mCreating swarm master \e[33m***\e[0m\n"
docker-machine create -d virtualbox --engine-opt="default-network=overlay:multihost" --engine-opt="kv-store=consul:$(docker-machine ip infra):8500" --engine-label="com.docker.network.driver.overlay.bind_interface=eth1" --engine-insecure-registry $(docker-machine ip registry):5000 swarm-0
docker $(docker-machine config swarm-0) run -d --restart="always" --net="bridge" $(docker-machine ip registry):5000/swarm join --addr "$(docker-machine ip swarm-0):2376" "token://$SWARM_TOKEN"
docker $(docker-machine config swarm-0) run -d --restart="always" --net="bridge" -p "3376:3376" -v "$HOME/.docker/machine/machines/swarm-0:/etc/docker" $(docker-machine ip registry):5000/swarm manage --tlsverify --tlscacert="/etc/docker/ca.pem" --tlscert="/etc/docker/server.pem" --tlskey="/etc/docker/server-key.pem" -H "tcp://0.0.0.0:3376" --strategy spread "token://$SWARM_TOKEN"
docker $(docker-machine config swarm-0) run -d --name consul -p 8500:8500 $(docker-machine ip registry):5000/consul -server -bootstrap-expect 1
docker $(docker-machine config swarm-0) run -d -v /var/run/docker.sock:/tmp/docker.sock -h registrator --name registrator-swarm-0 $(docker-machine ip registry):5000/registrator -internal consul://consul:8500

printf "\e[33m*** \e[32mCreating swarm-1 node as frontend \e[33m***\e[0m\n"
docker-machine create -d virtualbox --engine-opt="default-network=overlay:multihost" --engine-opt="kv-store=consul:$(docker-machine ip infra):8500" --engine-label="com.docker.network.driver.overlay.bind_interface=eth1" --engine-label="com.docker.network.driver.overlay.neighbor_ip=$(docker-machine ip swarm-0)" --engine-label="type=frontend" --engine-insecure-registry $(docker-machine ip registry):5000 swarm-1
docker $(docker-machine config swarm-1) run -d --restart="always" --net="bridge" $(docker-machine ip registry):5000/swarm join --addr "$(docker-machine ip swarm-1):2376" "token://$SWARM_TOKEN"
docker $(docker-machine config swarm-1) run -d -v /var/run/docker.sock:/tmp/docker.sock -h registrator --name registrator-swarm-1 $(docker-machine ip registry):5000/registrator -internal consul://consul:8500

printf "\e[33m*** \e[32mSetting the environment variables, please set the following \e[33m***\e[0m\n"
echo 'export DOCKER_HOST="tcp://$(docker-machine ip swarm-0):3376"'
echo 'export DOCKER_TLS_VERIFY=1'
echo 'export DOCKER_CERT_PATH="$HOME/.docker/machine/machines/swarm-0"'
