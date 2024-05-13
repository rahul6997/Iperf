#!/bin/bash

# Define the Docker network
NETWORK_NAME="iperf_network"
docker network rm $NETWORK_NAME
docker network create $NETWORK_NAME

# Ensure network is created
sleep 2

# Create multiple iperf3 servers with specific CPU affinities
docker run -d --name iperf-server1 --network $NETWORK_NAME --cpuset-cpus="0" iperf3-image
docker run -d --name iperf-server2 --network $NETWORK_NAME --cpuset-cpus="1" iperf3-image
docker run -d --name iperf-server3 --network $NETWORK_NAME --cpuset-cpus="2-3" iperf3-image

# Create multiple iperf3 clients
docker run -d --name iperf-client1 --network $NETWORK_NAME --cpuset-cpus="4" iperf3-image sleep infinity
docker run -d --name iperf-client2 --network $NETWORK_NAME --cpuset-cpus="5" iperf3-image sleep infinity

# Run tests without interactive terminal flags
docker exec iperf-client1 taskset -c 4 iperf3 -c iperf-server1 -t 30 -P 4 &
docker exec iperf-client2 taskset -c 5 iperf3 -c iperf-server2 -t 30 -P 4 &

# Wait for all tests to complete
wait

# Output results
echo "Results from iperf-client1:"
docker logs iperf-client1

echo "Results from iperf-client2:"
docker logs iperf-client2

# Cleanup
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker network rm $NETWORK_NAME
