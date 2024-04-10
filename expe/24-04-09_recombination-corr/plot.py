#!/usr/bin/env python3

# NOTE:
# Copied and modified from "$STORAGE/dataset/240309_custom_firmware_phase_eval_iq_norep_modgfsk/scripts/plot_attacks_perf.py"

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

# Do we show the plot interactively?
INTERACTIVE=True
# Do we save the plot on-disk?
SAVE=True

# Number of columns inside the CSV file.
NCOL=0

# Weither to smooth the plot.
SMOOTH_PLOT=False

ENABLE_LATEX_STYLE=True

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
# Y-axis, sum of the hamming distance.
y_hd_amp = []
y_hd_phr = []
y_hd_i_augmented = []
y_hd_q_augmented = []
y_hd_recombined = []

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
        y_hd_amp.append(int(float(row[2])))
        y_hd_phr.append(int(float(row[4])))
        y_hd_i_augmented.append(int(float(row[6])))
        y_hd_q_augmented.append(int(float(row[8])))
        y_hd_recombined.append(int(float(row[10])))

# DEBUG:
# print("x_nb={}".format(x_nb))

# * Plot

if ENABLE_LATEX_STYLE is True:
    # Use LaTeX style.
    libplot.enable_latex_fonts()

def myplot(x, y, param_dict, smooth=False):
    """Plot y(s) over x.

    :param smooth: Smooth the X data if True.

    :param param_dict: Dictionnary of parameters for plt.plot().

    :param labels: Labels associated to each y[i].

    """
    assert len(y) == len(param_dict)
    if smooth is True:
        x_smooth = np.linspace(min(x), max(x), 300)
        for yi in range(len(y)):
            spl = make_interp_spline(x, y[yi], k=3)
            y_smooth = spl(x_smooth)
            y[yi] = y_smooth
        x = x_smooth
    for yi, yv in enumerate(y):
        plt.plot(x, yv, **param_dict[yi])

plt.xlabel('Number of traces')

myplot(x_nb, [y_hd_amp, y_hd_phr, y_hd_i_augmented, y_hd_q_augmented, y_hd_recombined],
       param_dict=[
           {"color": "red", "label": "hd_amp", "linewidth": 2},
           {"color": "blue", "label": "hd_phr", "linewidth": 2},
           {"color": "green", "label": "hd_i_augmented", "linestyle": "--"},
           {"color": "cyan", "label": "hd_q_augmented", "linestyle": "--"},
           {"color": "purple", "label": "hd_recombined", "linewidth": 4}
       ], smooth=SMOOTH_PLOT)

plt.ylabel('Hamming distance (\# bits)')
# plt.ylim(top=60, bottom=0)
plt.legend(loc="upper left")

if SAVE is True:
    figure = plt.gcf()
    figure.set_size_inches(32, 18)
    plt.savefig(OUTFILE, bbox_inches='tight', dpi=300)
if INTERACTIVE is True:
    plt.show()
