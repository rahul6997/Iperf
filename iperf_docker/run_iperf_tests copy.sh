#!/bin/bash

# Default parameters
network_name="iperf_network"
test_duration=30
parallel_streams=4
use_affinity=0  # 0 means no CPU affinity, 1 means CPU affinity is used
congestion_control="cubic"  # Default to Cubic

# Read command line args
while getopts "n:t:p:a:c:" opt; do
  case $opt in
    n) network_name=$OPTARG;;
    t) test_duration=$OPTARG;;
    p) parallel_streams=$OPTARG;;
    a) use_affinity=$OPTARG;;
    c) congestion_control=$OPTARG;;  # Congestion control algorithm
    \?) echo "Invalid option -$OPTARG" >&2; exit 1;;
  esac
done

# Set TCP Congestion Control based on the selected algorithm
echo "Setting TCP Congestion Control to $congestion_control..."
sudo sysctl -w net.ipv4.tcp_congestion_control=$congestion_control

# Define the Docker network
echo "Creating Docker network..."
docker network rm $network_name
docker network create $network_name || { echo "Failed to create network"; exit 1; }

# Function to run a server with optional CPU affinity
docker_run_server() {
    if [[ $use_affinity -eq 1 ]]; then
        docker run -d --name $1 --network $network_name --cpuset-cpus="$2" iperf3-image
    else
        docker run -d --name $1 --network $network_name iperf3-image
    fi
}

# Function to run a client with optional CPU affinity
docker_run_client() {
    if [[ $use_affinity -eq 1 ]]; then
        docker run -d --name $1 --network $network_name --cpuset-cpus="$2" iperf3-image sleep infinity
    else
        docker run -d --name $1 --network $network_name iperf3-image sleep infinity
    fi
}

# Create servers and clients with or without CPU affinity
echo "Deploying servers and clients..."
docker_run_server "iperf-server1" "0"
docker_run_server "iperf-server2" "1"
docker_run_client "iperf-client1" "4"
docker_run_client "iperf-client2" "5"

# Run tests and redirect output to files
echo "Running tests..."
docker exec iperf-client1 iperf3 -c iperf-server1 -t $test_duration -P $parallel_streams &> "iperf-client1.log" &
docker exec iperf-client2 iperf3 -c iperf-server2 -t $test_duration -P $parallel_streams &> "iperf-client2.log" &

# Wait for all tests to complete
wait

# Output results
echo "Results from iperf-client1:"
cat iperf-client1.log

echo "Results from iperf-client2:"
cat iperf-client2.log

# Cleanup
echo "Cleaning up..."
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker network rm $network_name

echo "Test complete. All resources have been cleaned up."
