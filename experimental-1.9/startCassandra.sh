#!/bin/bash
echo "*** Starting first Cassandra instance ***"
docker run -d --name cass1 $(docker-machine ip registry):5000/cassandra cass1
echo "*** Cassandra instance started ***"
echo "docker logs -f cass1"
echo "docker run -d --name cass2 $(docker-machine ip registry):5000/cassandra cass1"
