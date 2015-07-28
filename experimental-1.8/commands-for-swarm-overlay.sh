# Create the infra node
docker-machine create -d virtualbox --virtualbox-boot2docker-url=http://sirile.github.io/files/boot2docker-1.8.iso infra

# Start Consul
docker $(docker-machine config infra) run -d -p 8500:8500 progrium/consul -server -bootstrap-expect 1

# Get swarm token
export SWARM_TOKEN=$(docker run swarm create)

# Create swarm master
docker-machine create -d virtualbox --virtualbox-boot2docker-url=http://sirile.github.io/files/boot2docker-1.8.iso --engine-opt="default-network=overlay:multihost" --engine-opt="kv-store=consul:$(docker-machine ip infra):8500" --engine-label="com.docker.network.driver.overlay.bind_interface=eth1" swarm-0

# Start up swarm
docker $(docker-machine config swarm-0) run -d --restart="always" --net="bridge" swarm:latest join --addr "$(docker-machine ip swarm-0):2376" "token://$SWARM_TOKEN"

docker $(docker-machine config swarm-0) run -d --restart="always" --net="bridge" -p "3376:3376" -v "$HOME/.docker/machine/machines/swarm-0:/etc/docker" swarm:latest manage --tlsverify --tlscacert="/etc/docker/ca.pem" --tlscert="/etc/docker/server.pem" --tlskey="/etc/docker/server-key.pem" -H "tcp://0.0.0.0:3376" --strategy spread "token://$SWARM_TOKEN"

# NB! This is different from the example as the certificates are passed directly from the host

# Start swarm node
docker-machine create -d virtualbox --virtualbox-boot2docker-url=http://sirile.github.io/files/boot2docker-1.8.iso --engine-opt="default-network=overlay:multihost" --engine-opt="kv-store=consul:$(docker-machine ip infra):8500" --engine-label="com.docker.network.driver.overlay.bind_interface=eth1" --engine-label="com.docker.network.driver.overlay.neighbor_ip=$(docker-machine ip swarm-0)" swarm-1

docker $(docker-machine config swarm-1) run -d --restart="always" --net="bridge" swarm:latest join --addr "$(docker-machine ip swarm-1):2376" "token://$SWARM_TOKEN"

# Point Docker at swarm
export DOCKER_HOST=tcp://"$(docker-machine ip swarm-0):3376"
export DOCKER_TLS_VERIFY=1
export DOCKER_CERT_PATH="$HOME/.docker/machine/machines/swarm-0"
