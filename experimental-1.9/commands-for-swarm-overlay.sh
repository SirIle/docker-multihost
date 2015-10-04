# Download and cache the experimental version of boot2docker
curl -L http://sirile.github.io/files/boot2docker-1.9.iso > $HOME/.docker/machine/cache/boot2docker-1.9.iso
export VIRTUALBOX_BOOT2DOCKER_URL=file://$HOME/.docker/machine/cache/boot2docker-1.9.iso

# Create the infra node
docker-machine create --driver virtualbox --engine-insecure-registry 192.168.99.100:5000 infra

# Start a registry
docker $(docker-machine config infra) run -d -p 5000:5000 --restart=always --name registry registry:2

# Start Consul
docker $(docker-machine config infra) run -d -p 8500:8500 progrium/consul -server -bootstrap-expect 1

# Get swarm token
export SWARM_TOKEN=$(docker $(docker-machine config infra) run swarm create)

# Create swarm master
docker-machine create -d virtualbox --engine-opt="default-network=overlay:multihost" --engine-opt="kv-store=consul:$(docker-machine ip infra):8500" --engine-label="com.docker.network.driver.overlay.bind_interface=eth1" --engine-insecure-registry $(docker-machine ip infra):5000 swarm-0

# Start up swarm
docker $(docker-machine config swarm-0) run -d --restart="always" --net="bridge" swarm:latest join --addr "$(docker-machine ip swarm-0):2376" "token://$SWARM_TOKEN"
docker $(docker-machine config swarm-0) run -d --restart="always" --net="bridge" -p "3376:3376" -v "$HOME/.docker/machine/machines/swarm-0:/etc/docker" swarm:latest manage --tlsverify --tlscacert="/etc/docker/ca.pem" --tlscert="/etc/docker/server.pem" --tlskey="/etc/docker/server-key.pem" -H "tcp://0.0.0.0:3376" --strategy spread "token://$SWARM_TOKEN"

# NB! This is different from the example as the certificates are passed directly from the host

# Start Consul inside the Swarm with the swarm-master in server mode
docker-1.9 $(docker-machine config swarm-0) run -d --name consul -p 8500:8500 progrium/consul -server -bootstrap-expect 1

# Start swarm node
docker-machine create -d virtualbox --engine-opt="default-network=overlay:multihost" --engine-opt="kv-store=consul:$(docker-machine ip infra):8500" --engine-label="com.docker.network.driver.overlay.bind_interface=eth1" --engine-label="com.docker.network.driver.overlay.neighbor_ip=$(docker-machine ip swarm-0)" --engine-insecure-registry $(docker-machine ip infra):5000 swarm-1

docker $(docker-machine config swarm-1) run -d --restart="always" --net="bridge" swarm:latest join --addr "$(docker-machine ip swarm-1):2376" "token://$SWARM_TOKEN"

# TODO: Start Consul agent on the node, not really needed any more as overlay networking abstracts this away
# If registrator is suitable, then more Consuls might make sense named the same as the swarm machine they're on
# The registrator on the node would point to the local Consul instance

# Point Docker at swarm
export DOCKER_HOST=tcp://"$(docker-machine ip swarm-0):3376"
export DOCKER_TLS_VERIFY=1
export DOCKER_CERT_PATH="$HOME/.docker/machine/machines/swarm-0"

# Start haproxy
docker-1.9 run -d --name=rest -p 80:80 -p 1936:1936 sirile/haproxy -consul=consul:8500

# Start example services, repeat these a few times
CONTAINER=$(docker run -d --dns 172.17.42.1 sirile/node-image-test)
# Register service to Consul, registrator in not (yet) suitable for this
curl -X post -d '{"Name":"test","ID":"'$CONTAINER'","Tags":["rest"],"Address":"'$(docker inspect --format="{{.NetworkSettings.IPAddress}}" $CONTAINER)'", "port":80}' http://$(docker inspect --format='{{.Node.IP}}' consul):8500/v1/agent/service/register
