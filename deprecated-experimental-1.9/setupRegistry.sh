#!/bin/sh
printf "\e[33m*** \e[32mCreating private registry server \e[33m***\e[0m\n"
if ! docker-machine inspect registry &> /dev/null; then
  printf "\e[33m*** \e[32mCreating local private registry server \e[33m***\e[0m\n"
  docker-machine create --driver virtualbox --virtualbox-memory 2048 registry
  REGISTRY_IP=$(docker-machine ip registry):5000
  docker-machine ssh registry "echo $'EXTRA_ARGS=\"--insecure-registry '$REGISTRY_IP'\"' | sudo tee -a /var/lib/boot2docker/profile && sudo /etc/init.d/docker restart"
  docker $(docker-machine config registry) run -d -p 5000:5000 --restart=always --name registry registry:2
else
  REGISTRY_IP=$(docker-machine ip registry):5000
fi
eval $(docker-machine env registry)
printf "\e[33m*** \e[32mFetching images to private registry \e[33m***\e[0m\n"
printf "\e[33m*** \e[32mFetching consul image \e[33m***\e[0m\n"
docker pull progrium/consul
docker tag progrium/consul $REGISTRY_IP/consul
docker push $REGISTRY_IP/consul
printf "\e[33m*** \e[32mFetching swarm image \e[33m***\e[0m\n"
docker pull swarm:latest
docker tag swarm:latest $REGISTRY_IP/swarm
docker push $REGISTRY_IP/swarm
printf "\e[33m*** \e[32mFetching registrator image \e[33m***\e[0m\n"
docker pull gliderlabs/registrator
docker tag gliderlabs/registrator $REGISTRY_IP/registrator
docker push $REGISTRY_IP/registrator
printf "\e[33m*** \e[32mFetching haproxy image to private registry \e[33m***\e[0m\n"
docker pull sirile/haproxy
docker tag sirile/haproxy $REGISTRY_IP/haproxy
docker push $REGISTRY_IP/haproxy
printf "\e[33m*** \e[32mFetching test image to private registry \e[33m***\e[0m\n"
docker pull sirile/node-image-test
docker tag sirile/node-image-test $REGISTRY_IP/node-image-test
docker push $REGISTRY_IP/node-image-test
printf "\e[33m*** \e[32mFetching Cassandra image to private registry \e[33m***\e[0m\n"
docker pull sirile/minicassandra
docker tag sirile/minicassandra $REGISTRY_IP/cassandra
docker push $REGISTRY_IP/cassandra
