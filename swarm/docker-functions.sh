#!/bin/bash
function dock() {
  # Point docker client and docker-machine to the given node
  eval "$(docker-machine env $@)"
}

# Remove all containers as well as clear out dangling images
function cleardock() {
  docker rm -f $(docker ps -aq) 2> /dev/null
  docker rmi $(docker images --filter "dangling=true" -q) 2> /dev/null
}

# Return public IP of a running container
function dockip() {
  docker inspect $(docker ps -f name=$@ -q) | grep IP\" | cut -d '"' -f 4
}

# Kill all running instances of given image with partial match
function dockrm() {
  docker rm -f $(docker ps | awk '{print $1,$2}' | grep $@ | awk '{print $1}')
}

# List running instances of a given image with partial match, showing none if no match
function dockpsi() {
  docker ps --filter id=nonexisting $(docker ps | awk '{print $1,$2}' | grep $@ | awk '{print $1}' | xargs -I{} echo --filter id={} | xargs)
}

# Checks that a node has a service running. Returns zero if service isn't running
function checkService() {
  return $(docker $(docker-machine config $1) ps | awk '{print $1,$2}' | grep $2 | wc -l)
}

# Checks if a node already exists. Returns non-zero if it does.
function checkNode() {
  ( docker-machine ls | grep "^$@ " ) >> /dev/null
}
