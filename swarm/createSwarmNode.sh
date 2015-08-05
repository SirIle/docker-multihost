#!/bin/bash

# Check if a machine already exists and quit if it does
function checkExisting() {
  ( docker-machine ls | grep "^$1 " ) >> /dev/null
  if [[ $? -eq 0 ]] ; then
    echo "ERROR: $1 already exists"
    exit 1
  fi
}

# Number zero is master, rest are normal swarm-nodes
[ $# -ne 1 ] || [ $1 == "-h" ] && { echo "Usage: $0 [-h] <id, 0 for master>"; exit 1; }
# Check that infra machine exists
( docker-machine ls | grep "^infra " ) >> /dev/null
if [[ $? -ne 0 ]] ; then
  echo "ERROR: Infra node doesn't exist, please create it first"
  exit 1
fi

LOCAL_INFRA_IP=$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' infra)
EXTERNAL_INFRA_IP=$(docker-machine ip infra)

if [ $1 -eq 0 ]
then
  NAME='swarm-master'
  # Check that the machine doesn't already exist
  checkExisting $NAME
  if [ $AWS_ACCESS_KEY_ID ]; then
    echo "** Creating swarm master with the name '$NAME' to AWS **"
    docker-machine create --driver amazonec2 --swarm --swarm-master --swarm-discovery consul://$LOCAL_INFRA_IP:8500 swarm-master
  else
    echo "** Creating swarm master with the name '$NAME' locally **"
    docker-machine create -d virtualbox --swarm --swarm-master --swarm-discovery consul://$EXTERNAL_INFRA_IP:8500 swarm-master
  fi
else
  ( docker-machine ls | grep "^swarm-master " ) >> /dev/null
  if [[ $? -ne 0 ]] ; then
    echo "ERROR: swarm-master doesn't exist, please create it first"
    exit 1
  fi
  NAME='swarm-app-'$1
  checkExisting $NAME
  if [ $AWS_ACCESS_KEY_ID ]; then
    echo "** Creating swarm node with the name '$NAME' to AWS **"
    docker-machine create --driver amazonec2 --swarm --swarm-discovery consul://$LOCAL_INFRA_IP:8500 $NAME
  else
    echo "** Creating swarm node with the name '$NAME' locally **"
    docker-machine create -d virtualbox --swarm --swarm-discovery consul://$EXTERNAL_INFRA_IP:8500 $NAME
  fi
fi
echo "** Starting consul and joining it to the infra node **"
if [ $AWS_ACCESS_KEY_ID ]; then
  docker $(docker-machine config $NAME) run -d -p 172.17.42.1:53:53 -p 172.17.42.1:53:53/udp -p 8301:8301 -p 8301:8301/udp -p 8500:8500 --name consul progrium/consul -join $LOCAL_INFRA_IP -advertise $(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' $NAME)
else
  docker $(docker-machine config $NAME) run -d -p 172.17.42.1:53:53 -p 172.17.42.1:53:53/udp -p 8301:8301 -p 8301:8301/udp -p 8500:8500 --name consul progrium/consul -join $EXTERNAL_INFRA_IP -advertise $(docker-machine ip $NAME)
fi
echo "** Starting registrator ** "
if [ $AWS_ACCESS_KEY_ID ]; then
  docker $(docker-machine config $NAME) run -d -v /var/run/docker.sock:/tmp/docker.sock -h registrator --name registrator gliderlabs/registrator consul://$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' $NAME):8500
else
  docker $(docker-machine config $NAME) run -d -v /var/run/docker.sock:/tmp/docker.sock -h registrator --name registrator gliderlabs/registrator consul://$(docker-machine ip $NAME):8500
fi
echo "** Started a new node with IP $(docker-machine ip $NAME) **"
