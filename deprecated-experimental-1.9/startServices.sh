printf "\e[33m*** \e[32mStarting HAProxy if not already running \e[33m***\e[0m\n"
if [[ $(docker ps | awk '{print $1,$2}' | grep haproxy | wc -l) -lt 1 ]]; then
  docker run -d --name=rest -p 80:80 -p 1936:1936 -e constraint:type==frontend $(docker-machine ip registry):5000/haproxy -consul=consul:8500
fi

printf "\e[33m*** \e[32mStarting three example services \e[33m***\e[0m\n"
docker run -d -e SERVICE_NAME=hello/v1 -e SERVICE_TAGS=rest --dns 172.17.42.1 -p :80 $(docker-machine ip registry):5000/node-image-test
docker run -d -e SERVICE_NAME=hello/v1 -e SERVICE_TAGS=rest --dns 172.17.42.1 -p :80 $(docker-machine ip registry):5000/node-image-test
docker run -d -e SERVICE_NAME=hello/v1 -e SERVICE_TAGS=rest --dns 172.17.42.1 -p :80 $(docker-machine ip registry):5000/node-image-test

printf "\e[33m*** \e[32mService available at \e[31mhttp://$(docker inspect --format='{{.Node.IP}}' rest)/hello/v1 \e[33m***\e[0m\n"
