# Download and cache the experimental version of boot2docker
curl -L http://sirile.github.io/files/boot2docker-1.9.iso > $HOME/.docker/machine/cache/boot2docker-1.9.iso
export VIRTUALBOX_BOOT2DOCKER_URL=file://$HOME/.docker/machine/cache/boot2docker-1.9.iso

# Create the infra node
docker-machine create -d virtualbox infra

# Start Consul
docker-1.9 $(docker-machine config infra) run -d -p 8500:8500 progrium/consul -server -bootstrap-expect 1

# Or use the docker-compose script

# Create frontend node
docker-machine create -d virtualbox --engine-opt="default-network=overlay:multihost" --engine-opt="kv-store=consul:$(docker-machine ip infra):8500" --engine-label="com.docker.network.driver.overlay.bind_interface=eth1" frontend

# 4.10.2015: A second Consul network is set-up inside the overlay network
docker-1.9 $(docker-machine config frontend) run -d --name frontend -p 8500:8500 progrium/consul -server -bootstrap-expect 1

# Start registrator on frontend node, idea is to register the public IP for the frontend services
docker-1.9 $(docker-machine config frontend) run --rm -v /var/run/docker.sock:/tmp/docker.sock -h registrator --name registrator gliderlabs/registrator -internal consul://frontend:8500

# Start haproxy on frontend node
docker-1.9 $(docker-machine config frontend) run -d --name=rest -p 80:80 -p 1936:1936 sirile/haproxy -consul=frontend:8500

# Start up a few example services with an exposed port
docker-1.9 run -d -e SERVICE_NAME=test -e SERVICE_TAGS=rest --dns 172.17.42.1 -p :80 sirile/node-image-test
docker-1.9 run -d -e SERVICE_NAME=test -e SERVICE_TAGS=rest --dns 172.17.42.1 -p :80 sirile/node-image-test
docker-1.9 run -d -e SERVICE_NAME=test -e SERVICE_TAGS=rest --dns 172.17.42.1 -p :80 sirile/node-image-test

# Create application node
docker-machine create -d virtualbox --engine-opt="default-network=overlay:multihost" --engine-opt="kv-store=consul:$(docker-machine ip infra):8500" --engine-label="com.docker.network.driver.overlay.bind_interface=eth1" --engine-label="com.docker.network.driver.overlay.neighbor_ip=$(docker-machine ip frontend)" application

# No need to start more Consul instances on the nodes as overlay networking abstracts the nodes away

unset VIRTUALBOX_BOOT2DOCKER_URL
