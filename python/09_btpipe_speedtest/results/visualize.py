import matplotlib.pyplot as plt
import numpy as np

rate_list = [
    "1.00 KiB",
    "2.00 KiB",
    "4.00 KiB",
    "8.00 KiB",
    "16.00 KiB",
    "32.00 KiB",
    "64.00 KiB",
    "128.00 KiB",
    "256.00 KiB",
    "512.00 KiB",
    "1.00 MiB",
    "10.00 MiB",
    "100.00 MiB",
    "1.00 GiB",
]

plt.figure(figsize=(12, 6), tight_layout=True)

# Create positions for the box plots
# Each rate will have two box plots (read and write) side by side
x_positions = []
for i in range(len(rate_list)):
    x_positions.append(i * 2.5)  # Position for read
    x_positions.append(i * 2.5 + 1)  # Position for write

# Create tick positions (in the middle of each pair of box plots)
tick_positions = [i * 2.5 + 0.5 for i in range(len(rate_list))]

for i, rate in enumerate(rate_list):
    bulk_read_rate = np.load(f"./btpipe_bulk_read_rates_{rate}.npy")
    bulk_write_rate = np.load(f"./btpipe_bulk_write_rates_{rate}.npy")

    # Divide all values by 10^6 to convert to MiB/s
    bulk_read_rate = bulk_read_rate / 10**6
    bulk_write_rate = bulk_write_rate / 10**6

    # Plot read box plot
    bp = plt.boxplot(
        bulk_read_rate, positions=[x_positions[i * 2]], widths=0.4, whis=[0, 100]
    )
    for median in bp["medians"]:
        median.set_color("blue")

    # Plot write box plot
    bp = plt.boxplot(
        bulk_write_rate, positions=[x_positions[i * 2 + 1]], widths=0.4, whis=[0, 100]
    )
    for median in bp["medians"]:
        median.set_color("red")

# Set the tick positions and labels
plt.xticks(tick_positions, rate_list, rotation=45, ha="center")

# Add a legend to distinguish between read and write
from matplotlib.lines import Line2D

legend_elements = [
    Line2D([0], [0], color="blue", lw=2, label="Read"),
    Line2D([0], [0], color="red", lw=2, label="Write"),
]
plt.legend(handles=legend_elements)

plt.title("BTPipe Speed Test")
plt.grid(alpha=0.5, axis="y")
plt.ylabel("Transfer Speed (MiB/s)")
plt.show()
