#!/usr/bin/env python3

"""Read the output CSV file from the Bash partner script and plot the results."""

import sys
import os
import numpy as np
import matplotlib.pyplot as plt
import csv
from scipy.interpolate import make_interp_spline, BSpline

import lib.plot as libplot

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
    y_kr = []
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
            y_kr.append(int(float(row[2])))
    if DEBUG:
        print("x_nb={}".format(x_nb))
        print("y_kr={}".format(y_kr))
    x_y[file] = {'x': np.asarray(x_nb), 'y': np.asarray(y_kr)}

# * Plot

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

libplot.enable_latex_fonts()

# plt.title('Key rank vs. Trace number')
plt.xlabel('Number of traces')

for key, value in x_y.items():
    myplot(value["x"], value["y"], {"label": key}, smooth=SMOOTH_PLOT)
plt.ylabel('Log2(Key rank)')
plt.ylim(top=128, bottom=0)
plt.legend(loc="upper right")

plt.gcf().set_size_inches(32, 18)
plt.savefig(OUTFILE, dpi=100, bbox_inches='tight')
if INTERACTIVE:
    plt.show()
plt.clf()
