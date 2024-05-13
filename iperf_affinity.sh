#!/bin/bash

echo "Starting iPerf3 with adjusted process priority"
echo "Select mode:"
echo "1. Server"
echo "2. Client"
read -p "Enter your choice (1 or 2): " mode

# Set a priority value: lower values mean higher priority. Normal users can only increase niceness (decrease priority).
priority=10

if [ "$mode" == "1" ]; then
    echo "Running iPerf3 server with increased niceness (lower priority)."
    nice -n $priority iperf3 -s
elif [ "$mode" == "2" ]; then
    read -p "Enter server address: " server_address
    echo "Running iPerf3 client with increased niceness (lower priority)."
    nice -n $priority iperf3 -c $server_address
else
    echo "Invalid choice. Exiting."
    exit 1
fi
