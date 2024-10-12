#!/usr/bin/env python3

"""Read the output CSV file from the Bash partner script and plot the results."""

import sys
import os
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import csv
from scipy.interpolate import make_interp_spline, BSpline

from scaff import plotters

# * Configuration

# CSV file name.
DIR=sys.argv[1]
OUTFILE=sys.argv[2]

# Weither to smooth the plot.
SMOOTH_PLOT=False

DEBUG=False

INTERACTIVE=False

# * CSV reader

# Dictionnary containing results of all csv files.
x_y = {}

for file in os.listdir(DIR):
    file_path = os.path.realpath(os.path.join(DIR, file))
    print("INFO: Open file: {}".format(file_path))
    # X-axis, number of traces.
    x_nb = []
    # Y-axis, log_2(key rank).
    y_kr_amp = []
    y_kr_phr = []
    y_kr_recombined = []
    # Read the CSV file into lists.
    with open(file_path, 'r') as csvfile:
        rows = csv.reader(csvfile, delimiter=';')
        # Iterate over lines.
        for i, row in enumerate(rows):
            # Skip header.
            if i == 0:
                continue
            # Skip not completed rows when .sh script is running.
            if row[1] == "":
                continue
            # Get data. Index is the column number.
            x_nb.append(int(float(row[0])))
            y_kr_amp.append(int(float(row[3])))
            y_kr_phr.append(int(float(row[6])))
            y_kr_recombined.append(int(float(row[9])))
    if DEBUG:
        print("x_nb={}".format(x_nb))
        print("y_kr_amp={}".format(y_kr_amp))
        print("y_kr_phr={}".format(y_kr_phr))
        print("y_kr_recombined={}".format(y_kr_recombined))
    x_y[file] = {'x': np.asarray(x_nb), 'y': {'y_kr_amp': np.asarray(y_kr_amp),
                                              'y_kr_phr': np.asarray(y_kr_phr),
                                              'y_kr_recombined': np.asarray(y_kr_recombined)}}

# * Plot

def myplot(x, y, param_dict, smooth=False, label=""):
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
    idx = 0
    for y_key in y:
        if param_dict[idx].get("label") is not None:
            label = param_dict[idx].get("label")
        else:
            label = "{}/{}".format(label, y_key)
        plt.plot(x, y[y_key], **dict(param_dict[idx], label=label))
        idx += 1

plotters.enable_latex_fonts()
matplotlib.rcParams.update({'font.size': 55})

# plt.title('Key rank vs. Trace number')
plt.xlabel('Traces')

for key, value in x_y.items():
    myplot(value["x"], value["y"], param_dict=[
        {"color": "red", "label": "Amplitude", "linewidth": 2},
        {"color": "blue", "label": "Phase", "linewidth": 2},
        {"color": "purple", "label": "Fusion (Amplitude + Phase)", "linewidth": 5}
    ], smooth=SMOOTH_PLOT, label=key)
plt.ylabel('Log2(Key rank)')
plt.ylim(top=128, bottom=0)
plt.legend(loc="upper right")

plt.gcf().set_size_inches(32, 18)
plt.savefig(OUTFILE, dpi=100, bbox_inches='tight')
if INTERACTIVE:
    plt.show()
plt.clf()
