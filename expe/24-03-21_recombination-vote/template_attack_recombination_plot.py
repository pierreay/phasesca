#!/usr/bin/env python3

# NOTE:
# Copied from "$STORAGE/dataset/240309_custom_firmware_phase_eval_iq_norep_modgfsk/scripts/plot_attacks_perf.py"

"""Read the output CSV file from the Bash partner script and plot the results."""

import sys
import numpy as np
import matplotlib.pyplot as plt
import csv
from scipy.interpolate import make_interp_spline, BSpline

import lib.plot as libplot

# * Configuration

# CSV file name.
FILE=sys.argv[1]
OUTFILE=sys.argv[2]

# Number of columns inside the CSV file.
NCOL=0

# Weither to smooth the plot.
SMOOTH_PLOT=False

# * CSV reader

print("Open {}...".format(FILE))

# Grep number of columns in CSV file.
if NCOL == 0:
    with open(FILE, 'r') as csvfile:
        line = csvfile.readline()
        nsep = line.count(';')
        NCOL = nsep + 1 if line[:-1] != ';' else nsep

print("NCOL={}".format(NCOL))

# X-axis, number of traces.
x_nb = []
# Y-axis, log_2(key rank).
y_kr = []

# Read the CSV file into lists.
with open(FILE, 'r') as csvfile:
    rows = csv.reader(csvfile, delimiter=';')
    # Iterate over lines.
    for i, row in enumerate(rows):
        # Skip header.
        if i == 0:
            continue
        # Skip not completed rows when .sh script is running.
        if row[1] == "":
            continue
        # Get data. Index is the column number. Do not index higher than NCOL.
        x_nb.append(int(float(row[0])))
        y_kr.append(int(float(row[1])))

print("x_nb={}".format(x_nb))
print("y_kr={}".format(y_kr))

# * Plot

# Use GGPlot style.
# plt.style.use("ggplot")
libplot.enable_latex_fonts()

def myplot(x, y, param_dict, smooth=False):
    """Plot y over x.

    :param smooth: Smooth the X data if True.

    :param param_dict: Dictionnary of parameters for plt.plot().

    """
    if smooth is True:
        spl = make_interp_spline(x, y, k=3)
        x_smooth = np.linspace(min(x), max(x), 300)
        y_smooth = spl(x_smooth)
        x = x_smooth
        y = y_smooth
    plt.plot(x, y, **param_dict)

# General:

# plt.title('Key rank vs. Trace number')
plt.xlabel('Number of traces')

# Key rank:

# myplot(x_nb, y_kr, {"color": "blue", "label": "Key rank", "marker": "."}, smooth=SMOOTH_PLOT)
myplot(x_nb, y_kr, {"color": "blue", "label": "Key rank"}, smooth=SMOOTH_PLOT)
plt.ylabel('Log2(Key rank)')
plt.ylim(top=128, bottom=0)
plt.legend(loc="upper left")

# General:

# plt.show()
plt.savefig(OUTFILE)
