#!/usr/bin/env python3

# Inspired from:
# https://ni4ai-blog.readthedocs.io/en/latest/blog/analysis/visualizing-phasor-timeseries.html

import numpy as np
import matplotlib.pyplot as plt

# * Trace parameters

# Trace sample rate [Msps].
SAMP_RATE=8e6

# * Import traces

amp = np.load("./amp__0.npy")
phr = np.load("./phr__0.npy")

i = np.load("./i__0.npy")
q = np.load("./q__0.npy")

i_augmented = np.load("./i_augmented__0.npy")
q_augmented = np.load("./q_augmented__0.npy")

# DONE:
# plt.plot(i_augmented)
# plt.show()

# * Convert to complex I/Q

iq = np.empty_like(i, dtype=np.complex64)
iq_augmented = np.empty_like(i_augmented, dtype=np.complex64)

for ii, iv in enumerate(i):
    iq[ii] = i[ii] + 1j * q[ii]
for ii, iv in enumerate(i_augmented):
    iq_augmented[ii] = i_augmented[ii] + 1j * q_augmented[ii]

# DONE:
# plt.specgram(iq_augmented, sides="twosided", mode="magnitude")
# plt.show()
# plt.plot(iq_augmented, sides="twosided", mode="magnitude")
# plt.show()

# * Plot polar 3D using colors

def plot_polar(mag, ang, title=""):
    """Polar plot of complex-valued data using color for time (3rd dimension).
    
    Inputs are magnitude and angle because of the polar projection used in
    matplotlib. It is the same as plotting I/Q using the scatter in non-polar
    mode. In order to have I/Q as inputs ("iq.real" instead of "mag", and
    "iq.imag" instead of "ang"), unset the "projection" parameter.

    :param mag: Magnitude of the complex-valued data.

    :param ang: Angle of the complex-valued data.

    """
    assert mag.shape == ang.shape

    # Using Polar projection transforms radians into visual angles.
    fig = plt.figure(figsize=(9,6))
    ax = fig.add_subplot(projection='polar')

    # Plot time using colors. Yellow = Older points ; Blue = New points.
    times = np.linspace(0, len(mag) / SAMP_RATE, num=len(mag)) # Time vector.
    cm = plt.get_cmap('cividis_r')                             # Color map.

    # Create the scatter plot.
    marker_size = 5
    im = ax.scatter(ang, mag, c=times, cmap=cm, s=marker_size)

    # Create the right color bar.
    cbar = fig.colorbar(im, ticks=[times[0], times[len(times)//2], times[-1]])
    cbar.ax.set_yticklabels([times[0], times[len(times)//2], times[-1]])
    cbar.ax.set_title("Time [s]")

    plt.title(title)
    plt.savefig("plot_polar_{}.pdf".format(title))

# NOTE: Copy of the plot_polar without polar projection for comparison purpose.
def plot_rectangular(real, imag, title=""):
    # Using Polar projection transforms radians into visual angles.
    fig = plt.figure(figsize=(9,6))
    ax = fig.add_subplot()

    # Plot time using colors. Yellow = Older points ; Blue = New points.
    times = np.linspace(0, len(real) / SAMP_RATE, num=len(real)) # Time vector.
    cm = plt.get_cmap('cividis_r')                             # Color map.

    # Create the scatter plot.
    marker_size = 5
    im = ax.scatter(imag, real, c=times, cmap=cm, s=marker_size)

    # Create the right color bar.
    cbar = fig.colorbar(im, ticks=[times[0], times[len(times)//2], times[-1]])
    cbar.ax.set_yticklabels([times[0], times[len(times)//2], times[-1]])
    cbar.ax.set_title("Time [s]")

    plt.title(title)
    plt.savefig("plot_rectangular_{}.pdf".format(title))

# DONE:
plot_polar(np.abs(iq), np.angle(iq), "abs(iq);angle(iq)")
plot_polar(np.abs(iq_augmented), np.angle(iq_augmented), "abs(iq_augmented);angle(iq_augmented)")
plot_polar(amp, phr, "amp;phr")
plot_rectangular(iq.real, iq.imag, "iq.real;iq.imag")
plot_rectangular(iq_augmented.real, iq_augmented.imag, "iq_augmented.real;iq_augmented.imag")
plot_rectangular(amp, phr, "amp;phr")
