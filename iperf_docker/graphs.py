import json
import matplotlib.pyplot as plt
import numpy as np

# Function to load data from a JSON file
def load_data(filename):
    with open(filename, 'r') as file:
        return json.load(file)

# Function to extract metrics
def extract_metrics(data):
    times = []
    bitrates = []
    packet_loss_percentages = []
    cpu_utilization = []

    # Extracting data from intervals for bitrate and packet loss
    for interval in data['intervals']:
        times.append(interval['sum']['end'])
        bitrates.append(interval['sum']['bits_per_second'])
        packet_loss_percentages.append(0)  # Placeholder for packet loss if not present

    # CPU utilization (assuming it is constant across the test duration)
    cpu_utilization = [data['end']['cpu_utilization_percent']['host_total']] * len(times)

    return times, bitrates, packet_loss_percentages, cpu_utilization

# Plotting function
def plot_metrics(times, bitrates, packet_loss_percentages, cpu_utilization, title):
    fig, axs = plt.subplots(3, 1, figsize=(10, 15), sharex=True)
    
    # Plot Bitrate
    axs[0].plot(times, bitrates, label='Bitrate (bps)', color='b', marker='o')
    axs[0].set_title('Bitrate Over Time')
    axs[0].set_ylabel('Bits per Second')

    # Plot Packet Loss
    axs[1].plot(times, packet_loss_percentages, label='Packet Loss (%)', color='r', marker='o')
    axs[1].set_title('Packet Loss Over Time')
    axs[1].set_ylabel('Packet Loss (%)')

    # Plot CPU Utilization
    axs[2].plot(times, cpu_utilization, label='CPU Utilization (%)', color='g', marker='o')
    axs[2].set_title('CPU Utilization Over Time')
    axs[2].set_ylabel('CPU Utilization (%)')
    axs[2].set_xlabel('Time (seconds)')

    for ax in axs:
        ax.legend()
        ax.grid(True)

    plt.tight_layout()
    plt.show()

# Load data
data_without_affinity = load_data('iperf-client1 without affinity.json')
data_with_affinity = load_data('iperf-client1 with affinity.json')

# Extract metrics
times_without, bitrates_without, packet_loss_without, cpu_without = extract_metrics(data_without_affinity)
times_with, bitrates_with, packet_loss_with, cpu_with = extract_metrics(data_with_affinity)

# Plot data
plot_metrics(times_without, bitrates_without, packet_loss_without, cpu_without, 'Performance Without CPU Affinity')
plot_metrics(times_with, bitrates_with, packet_loss_with, cpu_with, 'Performance With CPU Affinity')
