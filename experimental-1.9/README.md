# Docker 1.9-experimental

In this folder are a few files which contain commands I have used when trying to get the new overlay networking play along with Registrator and Consul. So far these experiments haven't been successful, I'll continue when the tools mature.

Running the commands requires an experimental version of the Docker client which is here called docker-1.9 to keep it separate from the normal released version which at the moment is 1.8.2.

The file commands-for-swarm-overlay.sh contains command for setting up a swarm with a private registry as overlay networking break outside connectivity from swarm nodes. This way the Infra node can be used for building images and they can be shared through the private registry. More information and an example demonstrating how to run a Cassandra cluster on the set-up can be found at http://sirile.github.io/2015/09/30/cassandra-cluster-on-docker-swarm-and-overlay-networking-using-docker-experimental-1.9.html.

# Setting up the swarm

{% highlight %}
./setupRegistry
./setupLocal.sh
./startServices.sh
./startCassandra.sh
{% endhighlight %}

## Cassandra example commands

### Listing the ring members

{% highlight bash %}
docker exec cass1 /cassandra/bin/nodetool status
{% endhighlight %}

### Connecting to cqlsh

{% highlight bash %}
docker exec -it cass1 /cassandra/bin/cqlsh
{% endhighlight %}

### Creating example keyspace

{% highlight bash %}
CREATE KEYSPACE demo WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 2 };

CREATE TABLE demo.users (
    userid text,
    firstname text,
    lastname text,
    PRIMARY KEY (userid)
);

INSERT INTO demo.users (userid, firstname, lastname) VALUES ('ile','Ilkka','Anttonen');
INSERT INTO demo.users (userid, firstname, lastname) VALUES ('another','Some','User');

SELECT * FROM demo.users where userid = 'ile';
{% endhighlight %}
