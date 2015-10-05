#!/bin/bash
printf "\e[33m*** \e[32mStarting first Cassandra instance \e[33m***\e[0m\n"
docker run -d --name cass1 $(docker-machine ip registry):5000/cassandra cass1
printf "\e[33m*** \e[32mCassandra instance started, some example commands below \e[33m***\e[0m\n"
echo "docker logs -f cass1"
echo "docker run -d --name cass2 $(docker-machine ip registry):5000/cassandra cass1"
