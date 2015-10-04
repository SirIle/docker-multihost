# Docker 1.9-experimental

In this folder are a few files which contain commands I have used when trying to get the new overlay networking play along with Registrator and Consul. So far these experiments haven't been successful, I'll continue when the tools mature.

Running the commands requires an experimental version of the Docker client which is here called docker-1.9 to keep it separate from the normal released version which at the moment is 1.8.2.

The file commands-for-swarm-overlay.sh contains command for setting up a swarm with a private registry as overlay networking break outside connectivity from swarm nodes. This way the Infra node can be used for building images and they can be shared through the private registry. More information and an example demonstrating how to run a Cassandra cluster on the set-up can be found at http://sirile.github.io/2015/09/30/cassandra-cluster-on-docker-swarm-and-overlay-networking-using-docker-experimental-1.9.html.
