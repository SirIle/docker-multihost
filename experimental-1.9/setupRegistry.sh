#!/bin/sh
echo "*** Creating private registry server ***"
docker-machine create --driver virtualbox --virtualbox-memory 2048 --engine-insecure-registry 192.168.99.100:5000 registry
if [[ "$(docker-machine ip registry)" != "192.168.99.100" ]]; then
  echo "Private registry on wrong IP address, 192.168.99.100 expected!"
  exit 1
fi
docker $(docker-machine config registry) run -d -p 5000:5000 --restart=always --name registry registry:2
echo "*** Fetching images to private registry ***"
echo "*** Fetching consul image ***"
docker $(docker-machine config registry) pull progrium/consul
docker $(docker-machine config registry) tag progrium/consul $(docker-machine ip registry):5000/consul
docker $(docker-machine config registry) push $(docker-machine ip registry):5000/consul
echo "*** Fetching swarm image ***"
docker $(docker-machine config registry) pull swarm:latest
docker $(docker-machine config registry) tag swarm:latest $(docker-machine ip registry):5000/swarm
docker $(docker-machine config registry) push $(docker-machine ip registry):5000/swarm
echo "*** Fetching registrator image ***"
docker $(docker-machine config registry) pull gliderlabs/registrator
docker $(docker-machine config registry) tag gliderlabs/registrator $(docker-machine ip registry):5000/registrator
docker $(docker-machine config registry) push $(docker-machine ip registry):5000/registrator
echo "*** Fetching haproxy image to private registry ***"
docker $(docker-machine config registry) pull sirile/haproxy
docker $(docker-machine config registry) tag sirile/haproxy $(docker-machine ip registry):5000/haproxy
docker $(docker-machine config registry) push $(docker-machine ip registry):5000/haproxy
echo "*** Fetching test image to private registry ***"
docker $(docker-machine config registry) pull sirile/node-image-test
docker $(docker-machine config registry) tag sirile/node-image-test $(docker-machine ip registry):5000/node-image-test
docker $(docker-machine config registry) push $(docker-machine ip registry):5000/node-image-test
echo "*** Fetching Cassandra image to private registry ***"
docker $(docker-machine config registry) pull sirile/minicassandra
docker $(docker-machine config registry) tag sirile/minicassandra $(docker-machine ip registry):5000/cassandra
docker $(docker-machine config registry) push $(docker-machine ip registry):5000/cassandra
