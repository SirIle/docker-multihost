#!/bin/bash
# Add logging to the swarm: start LogBox and Kibana on infra, add LogSpout to other nodes
source docker-functions.sh

# Check that infra exists and start LogBox if not already running
checkNode infra
if [[ $? -ne 0 ]] ; then
  echo "ERROR: Machine infra doesn't exist, please create it first"
  exit 1
fi
# Start logbox if not already running
checkService infra logbox
if [ $? -eq 0 ]; then
  echo "** Starting LogBox and Kibana on infra **"
  docker $(docker-machine config infra) run -d --name logbox -h logbox -p 5000:5000/udp -p 9200:9200 sirile/minilogbox
  if [ $AWS_ACCESS_KEY_ID ]; then
    docker $(docker-machine config infra) run -d -p 5601:5601 -h kibanabox --name kibanabox sirile/kibanabox http://$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' infra):9200
  else
    docker $(docker-machine config infra) run -d -p 5601:5601 -h kibanabox --name kibanabox sirile/kibanabox http://$(docker-machine ip infra):9200
  fi
else
  echo "** LogBox already running on infra **"
fi

# Loop through swarm servers and start logspout as needed
SWARM_MEMBERS=$(docker-machine ls | grep swarm | awk '{print $1}' | xargs)
echo "** Servers in the swarm: $SWARM_MEMBERS **"
for server in $SWARM_MEMBERS; do
  checkService $server logspout
  if [ $? -eq 0 ]; then
    echo "** Starting logspout on $server"
    if [ $AWS_ACCESS_KEY_ID ]; then
      docker $(docker-machine config $server) run -d --name logspout -h logspout -p 8100:8000 -v /var/run/docker.sock:/tmp/docker.sock progrium/logspout syslog://$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' infra):5000
    else
      docker $(docker-machine config $server) run -d --name logspout -h logspout -p 8100:8000 -v /var/run/docker.sock:/tmp/docker.sock progrium/logspout syslog://$(docker-machine ip infra):5000
    fi
  else
    echo "** Logspout already running on $server"
  fi
done

echo "** Logging system started, Kibana is available at http://$(docker-machine ip infra):5601 **"
