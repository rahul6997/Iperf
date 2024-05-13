# Use the official Ubuntu base image
FROM ubuntu:latest

# Install iPerf3 and util-linux for the taskset utility
RUN apt-get update && \
    apt-get install -y iperf3 util-linux && \
    rm -rf /var/lib/apt/lists/*

# Expose the default iPerf3 port
EXPOSE 5201

# Set the container to run iPerf3 in server mode by default
CMD ["iperf3", "-s"]
