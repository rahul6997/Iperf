#!/bin/bash

# Default parameters
network_name="iperf_network"
test_duration=30
parallel_streams=4
use_affinity=0  # 0 means no CPU affinity, 1 means CPU affinity is used
congestion_control="cubic"  # Default to Cubic
buffer_length=131072  # Adjusted buffer length to 128 KB for optimal performance.

# Read command line args
while getopts "n:t:p:a:c:b:" opt; do
  case $opt in
    n) network_name=$OPTARG;;
    t) test_duration=$OPTARG;;
    p) parallel_streams=$OPTARG;;
    a) use_affinity=$OPTARG;;
    c) congestion_control=$OPTARG;;  # Congestion control algorithm
    b) buffer_length=$OPTARG;;  # Buffer length for iPerf, can be overridden by command line
    \?) echo "Invalid option -$OPTARG" >&2; exit 1;;
  esac
done

# Set TCP Congestion Control and adjust TCP settings
if [[ "$(uname)" == "Linux" ]]; then
  echo "Setting TCP Congestion Control to $congestion_control..."
  sudo sysctl -w net.ipv4.tcp_congestion_control=$congestion_control
  sudo sysctl -w net.ipv4.tcp_retries2=5
  sudo sysctl -w net.core.rmem_max=2500000
  sudo sysctl -w net.core.wmem_max=2500000
else
  echo "TCP Congestion Control is set to $congestion_control"
fi

echo "Creating Docker network..."
docker network rm $network_name 2>/dev/null
docker network create --driver bridge --opt com.docker.network.driver.mtu=1450 $network_name || { echo "Failed to create network"; exit 1; }

# Enhanced functions with network tuning capabilities
docker_run_server() {
    if [[ $use_affinity -eq 1 ]]; then
        docker run --cap-add=NET_ADMIN -d --name $1 --network $network_name --cpuset-cpus="$2" iperf3-image
    else
        docker run --cap-add=NET_ADMIN -d --name $1 --network $network_name iperf3-image
    fi
}

docker_run_client() {
    docker_opts="--cap-add=NET_ADMIN -d --name $1 --network $network_name"
    [[ $use_affinity -eq 1 ]] && docker_opts+=" --cpuset-cpus=$2"
    docker run $docker_opts iperf3-image sleep infinity
}

# Create servers and clients with or without CPU affinity
echo "Deploying servers and clients..."
docker_run_server "iperf-server1" "0"
docker_run_server "iperf-server2" "1"
docker_run_client "iperf-client1" "4"
docker_run_client "iperf-client2" "5"

# Function to monitor CPU usage on macOS
monitor_cpu_usage() {
  end_time=$((SECONDS + test_duration + 5)) # add buffer time
  while [ $SECONDS -lt $end_time ]; do
    ps -A -o %cpu,command | awk '/iperf/ {print $1}' >> cpu_usage.log
    sleep 1
  done
}

echo "Monitoring CPU usage..."
monitor_cpu_usage &

# Run tests and redirect output to logs, including extended metrics
echo "Running tests..."
docker exec iperf-client1 iperf3 -c iperf-server1 -u -t $test_duration -P $parallel_streams -J &> "iperf-client1.json" &
docker exec iperf-client2 iperf3 -c iperf-server2 -u -t $test_duration -P $parallel_streams -J &> "iperf-client2.json" &

# Wait for all tests to complete
wait

# Output results
echo "Results from iperf-client1:"
cat iperf-client1.json
echo "Results from iperf-client2:"
cat iperf-client2.json

# Cleanup
echo "Cleaning up..."
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker network rm $network_name

echo "Test complete. All resources have been cleaned up."
