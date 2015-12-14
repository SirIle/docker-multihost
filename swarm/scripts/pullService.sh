#!/bin/bash
if [ $AWS_ACCESS_KEY_ID ]; then
  REGISTRY_IP=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' registry-aws):5000
  eval $(docker-machine env registry-aws)
else
  REGISTRY_IP=$(docker-machine ip registry):5000
  eval $(docker-machine env registry)
fi
printf "\e[33m*** \e[32mPulling image $1 to private registry \e[33m***\e[0m\n"
NAME=$REGISTRY_IP/$(basename $1)
docker pull $1
docker tag $1 $NAME
docker push $NAME
printf "\e[33m*** \e[32mTagged the image with name $NAME and pushed \e[33m***\e[0m\n"
