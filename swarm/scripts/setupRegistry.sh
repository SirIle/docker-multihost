#!/bin/bash
if [ $AWS_ACCESS_KEY_ID ]; then
  # Check that the machine doesn't already exist
  if ! docker-machine inspect registry-aws &> /dev/null; then
    printf "\e[33m*** \e[32mCreating private registry server on AWS \e[33m***\e[0m\n"
    docker-machine create -d amazonec2 registry-aws
    REGISTRY_IP=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' registry-aws):5000
    # Modify the registry to be insecure
    docker-machine ssh registry-aws "sudo sed -i \"/^ExecStart=/ s/\$/ --insecure-registry=$REGISTRY_IP/\" /etc/systemd/system/docker.service && sudo systemctl daemon-reload && sudo service docker restart"
    docker $(docker-machine config registry-aws) run -d -p 5000:5000 --restart=always --name registry registry:2
  else
    REGISTRY_IP=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' registry-aws):5000
  fi
  eval $(docker-machine env registry-aws)
else
  # Check that the machine doesn't already exist
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
fi
# Pull the images to the registry machine, tag them and push to private registry
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
docker pull kidibox/registrator
docker tag kidibox/registrator $REGISTRY_IP/registrator
docker push $REGISTRY_IP/registrator
printf "\e[33m*** \e[32mFetching haproxy image to private registry \e[33m***\e[0m\n"
docker pull sirile/haproxy
docker tag sirile/haproxy $REGISTRY_IP/haproxy
docker push $REGISTRY_IP/haproxy
printf "\e[33m*** \e[32mFetching minilogbox image to private registry \e[33m***\e[0m\n"
docker pull sirile/minilogbox
docker tag sirile/minilogbox $REGISTRY_IP/minilogbox
docker push $REGISTRY_IP/minilogbox
printf "\e[33m*** \e[32mFetching kibanabox image to private registry \e[33m***\e[0m\n"
docker pull sirile/kibanabox
docker tag sirile/kibanabox $REGISTRY_IP/kibanabox
docker push $REGISTRY_IP/kibanabox
printf "\e[33m*** \e[32mFetching logspout image to private registry \e[33m***\e[0m\n"
docker pull progrium/logspout
docker tag progrium/logspout $REGISTRY_IP/logspout
docker push $REGISTRY_IP/logspout
printf "\e[33m*** \e[32mFetching prometheus image to private registry \e[33m***\e[0m\n"
docker pull prom/prometheus
docker tag prom/prometheus $REGISTRY_IP/prometheus
docker push $REGISTRY_IP/prometheus
printf "\e[33m*** \e[32mFetching cadvisor image to private registry \e[33m***\e[0m\n"
docker pull google/cadvisor:latest
docker tag google/cadvisor:latest $REGISTRY_IP/cadvisor
docker push $REGISTRY_IP/cadvisor
