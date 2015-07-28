# Create the infra node
docker-machine create -d virtualbox --virtualbox-boot2docker-url=http://sirile.github.io/files/boot2docker-1.8.iso infra

# Start Consul
docker-1.8 $(docker-machine config infra) run -d -p 8500:8500 progrium/consul -server -bootstrap-expect 1

# Or use the docker-compose script

# Create frontend node
docker-machine create -d virtualbox --virtualbox-boot2docker-url=http://sirile.github.io/files/boot2docker-1.8.iso --engine-opt="default-network=overlay:multihost" --engine-opt="kv-store=consul:$(docker-machine ip infra):8500" --engine-label="com.docker.network.driver.overlay.bind_interface=eth1" frontend

# Is there a need to start consul also on frontend? How to register rest address?

# Start registrator on frontend node, idea is to register the public IP for the frontend services
docker-1.8 $(docker-machine config frontend) run -d -v /var/run/docker.sock:/tmp/docker.sock -h registrator --name registrator gliderlabs/registrator consul://`docker-machine ip infra`:8500

# Start haproxy on frontend node
docker-1.8 $(docker-machine config frontend) run -d --name=rest -p 80:80 -p 1936:1936 sirile/haproxy -consul=`docker-machine ip infra`:8500

# Dry run:
# docker run --dns 172.17.42.1 --rm sirile/haproxy -consul=consul.service.consul:8500 -dry -once

# Create application node
docker-machine create -d virtualbox --virtualbox-boot2docker-url=http://sirile.github.io/files/boot2docker-1.8.iso --engine-opt="default-network=overlay:multihost" --engine-opt="kv-store=consul:$(docker-machine ip infra):8500" --engine-label="com.docker.network.driver.overlay.bind_interface=eth1" --engine-label="com.docker.network.driver.overlay.neighbor_ip=$(docker-machine ip frontend)" application

# Start consul and join infra consul

# Start registrator
docker-1.8 run -d -v /var/run/docker.sock:/tmp/docker.sock -h registrator --name registrator gliderlabs/registrator -internal consul://`docker-machine ip infra`:8500

# Start example service
docker-1.8 run -d -e SERVICE_NAME=hello/v1 -e SERVICE_TAGS=rest -h hello1 --name hello1 sirile/scala-boot-test
